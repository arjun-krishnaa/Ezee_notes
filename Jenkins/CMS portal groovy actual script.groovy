import groovy.json.JsonSlurperClassic

// === Helper Functions ===

def prepareServers(String s3Bucket, String s3File) {
    sh """
        mkdir -p "${WORKSPACE}/tmp"
        aws s3 cp "s3://${s3Bucket}/${s3File}" "${WORKSPACE}/tmp/servers.json"
    """

    if (!fileExists("${WORKSPACE}/tmp/servers.json")) error("servers.json not found")

    def jsonText = readFile("${WORKSPACE}/tmp/servers.json")
    def json = new JsonSlurperClassic().parseText(jsonText)

    def servers = []
    servers += (json.staging ?: [])
    servers += (json.production ?: [])

    if (!servers) error("No servers found in servers.json")

    servers.each { srv ->
        ['name','instanceId','accountId','region','role'].each { k ->
            if (!srv[k]?.trim()) error("Invalid server entry: ${srv}")
        }
    }
    return servers
}

def getTriggeredUser() {
    def user = 'AUTO'
    try {
        def causes = currentBuild.getBuildCauses()
        def userCause = causes.find { it._class?.contains('UserIdCause') }
        if (userCause) {
            user = userCause.userId ?: userCause.userName ?: 'AUTO'
        }
    } catch (err) {
        echo "⚠ Could not get build cause: ${err}"
    }
    return user
}

def sendTeamsMessage(String status) {
    withCredentials([string(credentialsId: 'PHP-PORTAL-UPDATES', variable: 'WEBHOOK_URL')]) {
        def payload = [
            project_name : env.JOB_NAME,
            build_number : env.BUILD_NUMBER,
            build_status : status,
            update_type  : env.UPDATE_TYPE ?: 'N/A',
            server_name  : env.SELECTED_SERVER ?: 'N/A',
            triggered_by : env.TRIGGERED_BY ?: 'AUTO'
        ]
        writeFile file: 'payload.json', text: groovy.json.JsonOutput.toJson(payload)
        sh 'curl -s -X POST -H "Content-Type: application/json" -d @payload.json "$WEBHOOK_URL"'
    }
}

// === MAIN PIPELINE ===

pipeline {
    agent any

    options {
        timestamps()
    }

    parameters {
        choice(
            name: 'UPDATE_TYPE',
            choices: [
                'cms-portal',
                'docmediagen',
                'cms-header',
                'banner'
            ],
            description: 'Choose which update script to run'
        )
    }

    environment {
        S3_BUCKET      = 'ezin-jenkins-cicd/ezeebits'
        S3_SERVER_FILE = 'server/servers.json'
        JENKINS_ACCOUNT_ID = '995202495874'
    }

    stages {

        stage('Collect Inputs') {
            steps {
                script {
                    env.TRIGGERED_BY = getTriggeredUser()
                    env.UPDATE_TYPE  = params.UPDATE_TYPE
                    echo "Triggered by: ${env.TRIGGERED_BY}"
                    echo "Selected update type: ${env.UPDATE_TYPE}"
                }
            }
        }

        stage('Select Server') {
            steps {
                script {
                    def serversList = prepareServers(env.S3_BUCKET, env.S3_SERVER_FILE)

                    def selectedName = input(
                        id: 'SelectServer',
                        message: "Select target server for ${env.UPDATE_TYPE} update",
                        parameters: [
                            choice(
                                name: 'SERVER',
                                choices: serversList.collect { it.name }.join('\n'),
                                description: 'Select the target server'
                            )
                        ]
                    )

                    def selected = serversList.find { it.name == selectedName }
                    if (!selected) error("Invalid server: ${selectedName}")

                    env.SELECTED_SERVER  = selected.name
                    env.INSTANCE_ID      = selected.instanceId
                    env.SELECTED_ACCOUNT = selected.accountId
                    env.AWS_REGION       = selected.region
                    env.SELECTED_ROLE    = selected.role

                    echo "Selected server: ${env.SELECTED_SERVER}"
                }
            }
        }

        stage('Execute Update Script') {
            steps {
                script {
                    // Map update types to script paths
                    def scriptMap = [
                        'cms-portal'  : '/usr/jenkins/cms-portal-update.sh',
                        'docmediagen' : '/usr/jenkins/docmediagen-update.sh',
                        'cms-header'  : '/usr/jenkins/cms-header-update.sh',
                        'banner'      : '/usr/jenkins/banner-update.sh'
                    ]

                    def scriptPath = scriptMap[env.UPDATE_TYPE]
                    if (!scriptPath) error("Unknown update type: ${env.UPDATE_TYPE}")

                    echo "Executing ${scriptPath} on ${env.SELECTED_SERVER} via SSM"

                    // Define the SSM execution logic as a closure for reuse
                    def runSsmUpdate = {
                        def commandId = sh(
                            script: """
                                aws ssm send-command \
                                    --targets Key=InstanceIds,Values=${env.INSTANCE_ID} \
                                    --document-name AWS-RunShellScript \
                                    --comment "Run ${scriptPath} via Jenkins" \
                                    --parameters 'commands=["sudo ${scriptPath}"]' \
                                    --region ${env.AWS_REGION} \
                                    --query "Command.CommandId" \
                                    --output text
                            """,
                            returnStdout: true
                        ).trim()

                        echo "SSM Command ID: ${commandId}"

                        // Wait for completion (don't fail pipeline on wait timeout)
                        sh """
                            aws ssm wait command-executed \
                                --command-id ${commandId} \
                                --instance-id ${env.INSTANCE_ID} \
                                --region ${env.AWS_REGION} || true
                        """

                        // Fetch and parse output
                        def output = sh(
                            script: """
                                aws ssm get-command-invocation \
                                    --command-id ${commandId} \
                                    --instance-id ${env.INSTANCE_ID} \
                                    --region ${env.AWS_REGION} \
                                    --query '{Status:Status, StdOut:StandardOutputContent, StdErr:StandardErrorContent}' \
                                    --output json
                            """,
                            returnStdout: true
                        ).trim()

                        def json = readJSON text: output

                        echo "---- STDOUT ----"
                        (json.StdOut?.trim() ?: 'No standard output').split('\n').each { echo it }

                        echo "---- STDERR ----"
                        (json.StdErr?.trim() ?: 'No standard error').split('\n').each { echo it }

                        echo "============================"

                        if (json.Status != 'Success') {
                            error "Update failed on ${env.SELECTED_SERVER}. Status: ${json.Status}"
                        } else {
                            echo "✅ Update completed successfully on ${env.SELECTED_SERVER}"
                        }
                    }

                    // 🔑 Conditional role assumption: same-account vs cross-account
                    if (env.SELECTED_ACCOUNT == env.JENKINS_ACCOUNT_ID) {
                        echo "🟢 Same AWS account (${env.JENKINS_ACCOUNT_ID}) → using Jenkins EC2 IAM role"
                        runSsmUpdate()
                    } else {
                        echo "🔁 Cross-account → assuming role: ${env.SELECTED_ROLE} in account ${env.SELECTED_ACCOUNT}"
                        withAWS(
                            role: "arn:aws:iam::${env.SELECTED_ACCOUNT}:role/${env.SELECTED_ROLE}",
                            roleSessionName: "UpdateSession-${env.BUILD_NUMBER}",
                            region: env.AWS_REGION,
                            duration: 3600 // optional: extend session if scripts run long
                        ) {
                            runSsmUpdate()
                        }
                    }
                }
            }
        }
    }
  

    post {
        always {
            echo "Job completed: Type=${env.UPDATE_TYPE}, Server=${env.SELECTED_SERVER ?: 'N/A'}, Triggered by=${env.TRIGGERED_BY ?: 'AUTO'}"
        }
        success { sendTeamsMessage('SUCCESS') }
        failure { sendTeamsMessage('FAILED') }
        aborted { sendTeamsMessage('ABORTED') }
    }
}
