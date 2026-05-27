import groovy.json.JsonSlurperClassic

pipeline {
    agent any

    options {
        timestamps()
        skipDefaultCheckout(true)   
        disableConcurrentBuilds()
    }
    
    parameters {
        
        booleanParam(name: 'CHATCORE_MANUAL_BUILD',  defaultValue: false, description: 'Trigger manual build?')
        booleanParam(name: 'CHATCORE_MANUAL_DEPLOY', defaultValue: false, description: 'Trigger manual deployment?')
    }

    
    environment {
        TOOLS_DIR  = "${WORKSPACE}/tools"

        JAVA_HOME  = "${TOOLS_DIR}/jdk-25"
        MAVEN_HOME = "${TOOLS_DIR}/maven-4"
        MAVEN_CMD  = "${MAVEN_HOME}/bin/mvn"
        PATH       = "${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${env.PATH}"

        MAVEN_REPO     = "/usr/app/maven/repository"
        S3_BUCKET      = '28-feb-demo/ezeebits/server'
        AWS_REGION     = 'ap-south-1'
        S3_SERVER_FILE = "versions/servers-10.json"   // object path within the bucket
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Ensure Java 25 & Maven 4') {
            when {
                expression {
                    !params.CHATCORE_MANUAL_DEPLOY
                }
            }
            steps {
                sh '''
                  set -e
                  mkdir -p "$TOOLS_DIR"

                  ARCH=$(uname -m)
                  echo "Detected architecture: $ARCH"

                  if [ "$ARCH" = "aarch64" ]; then
                    JDK_URL="https://corretto.aws/downloads/latest/amazon-corretto-25-aarch64-linux-jdk.tar.gz"
                  else
                    JDK_URL="https://corretto.aws/downloads/latest/amazon-corretto-25-x64-linux-jdk.tar.gz"
                  fi

                  # ---- Java 25 ----
                  if [ -x "$JAVA_HOME/bin/java" ]; then
                    if "$JAVA_HOME/bin/java" -version >/dev/null 2>&1; then
                      echo "Java 25 already valid"
                    else
                      rm -rf "$JAVA_HOME"
                    fi
                  fi

                  if [ ! -d "$JAVA_HOME" ]; then
                    curl -L -o /tmp/jdk25.tar.gz "$JDK_URL"
                    tar -xzf /tmp/jdk25.tar.gz -C "$TOOLS_DIR"
                    mv "$TOOLS_DIR"/amazon-corretto-25* "$JAVA_HOME"
                  fi

                  # ---- Maven 4 ----
                  if [ ! -d "$MAVEN_HOME" ]; then
                    curl -L -o /tmp/maven4.tar.gz \
                      https://dlcdn.apache.org/maven/maven-4/4.0.0-rc-5/binaries/apache-maven-4.0.0-rc-5-bin.tar.gz
                    tar -xzf /tmp/maven4.tar.gz -C "$TOOLS_DIR"
                    mv "$TOOLS_DIR"/apache-maven-4.0.0-rc-5 "$MAVEN_HOME"
                  fi

                  "$JAVA_HOME/bin/java" -version
                  "$MAVEN_CMD" -version
                '''
            }
        }
        stage('Prepare Environment') {
            steps {
                script {
                    // basic env setup
                    env.BRANCH_LOWER   = (env.BRANCH_NAME ?: 'unknown').toLowerCase()
                    env.SAFE_BRANCH    = (env.BRANCH_NAME ?: 'unknown').replaceAll(/[^a-zA-Z0-9]/, '-')
                    env.dateTag        = new Date().format('yyyyMMdd', TimeZone.getTimeZone('Asia/Kolkata'))
                    env.versionStr     = "chatcore-${env.SAFE_BRANCH}-${env.dateTag}_${env.BUILD_NUMBER}"
                    env.IS_RELEASE     = (env.BRANCH_LOWER == 'release').toString()
                    env.JENKINS_ACCOUNT_ID = "590182060736"
                    env.PROD_FILEPATH  = "prod"
                    env.NONPROD_FILEPATH = "non-prod"
                    env.TRIGGERED_BY = getTriggeredUser()

                    // download server JSON from S3 into workspace/tmp/servers.json
                    sh """
                        mkdir -p "${WORKSPACE}/tmp"
                        aws s3 cp "s3://${S3_BUCKET}/${S3_SERVER_FILE}" "${WORKSPACE}/tmp/servers.json"
                    """

                    if (!fileExists("${WORKSPACE}/tmp/servers.json")) {
                        error("Failed to download servers.json from s3://${S3_BUCKET}/${S3_SERVER_FILE}")
                    } else {
                        echo "Downloaded server list to ${WORKSPACE}/tmp/servers.json"
                    }
                } 
            } 
        } 

        stage('Build & Upload to S3') {
            // run for CI builds or when user requested manual build (but not when doing manual deploy-only)
            when { 
                expression { 
                    return params.CHATCORE_MANUAL_BUILD || !params.CHATCORE_MANUAL_DEPLOY 
                } 
            }
            steps {
                dir('services') {
                    sh """
                        mkdir -p src/main/webapp
                        echo "Version: ${env.versionStr}" > src/main/webapp/version.txt
                        echo "Branch: ${env.BRANCH_NAME}" >> src/main/webapp/version.txt
                        echo "Build: ${env.BUILD_NUMBER}" >> src/main/webapp/version.txt
                        echo "Time: \$(date '+%Y-%m-%d %H:%M:%S')" >> src/main/webapp/version.txt

                     """
                    sh """
                        ${MAVEN_CMD} clean package \
                          -Dmaven.repo.local=${MAVEN_REPO} \
                          -Dbuild.version=${env.versionStr} \
                          -Dbuild.time=${env.dateTag} \
                          -Dbuild.branch=${env.BRANCH_NAME} \
                          -Dbuild.number=${env.BUILD_NUMBER}
                    """
                }

                script {
                    def s3Folder = (env.IS_RELEASE.toBoolean()) ? "${env.PROD_FILEPATH}/${env.SAFE_BRANCH}" : "${env.NONPROD_FILEPATH}/${env.SAFE_BRANCH}"

                    sh """
                        echo "Finding WAR file..."
                        WAR_FILE=\$(find . -name "*.war" | head -1)

                        echo "WAR found at: \$WAR_FILE"

                        echo "Uploading WAR to S3..."
                        aws s3 cp "\$WAR_FILE" s3://${S3_BUCKET}/${s3Folder}/${versionStr}.war
                    """
                }
            }
        }
       
        stage('Manual Deploy') {
            when { expression { return params.CHATCORE_MANUAL_DEPLOY } }
            steps {
                echo "Manual deploy triggered"
                script {
                    def selectedServer = selectServer()
                    def deployVersion = selectVersion()
                    echo "Selected version to deploy: ${deployVersion}"
                    def warPath = "s3://${S3_BUCKET}/${deployVersion}"
                    deployToInstance(warPath, selectedServer)
                }
            }
        }

        stage('Clean Up Repository') {
            steps {
                echo "Cleaning up repository..."
                sh """
                    rm -rf ${WORKSPACE}/*
                    echo "Workspace cleaned up."
                """
            }
        }

    }

    post {
        always {
            echo "Pipeline finished for branch ${env.BRANCH_NAME}"
        }
        success {
            sendTeamsNotification("SUCCESS")
        }
        failure {
            sendTeamsNotification("FAILED")
        }
        aborted {
            sendTeamsNotification("ABORTED")
        }
    }
} 

// ----------------  functions ----------------
def deployToInstance(String s3Path, def selectedServer) {
    script {

        echo "Deploying ${s3Path} → Account=${selectedServer.accountId}, Instance=${selectedServer.instanceId}, Region=${selectedServer.region}"

        // --- Function that actually runs the SSM command ---
        def runSsm = { server ->
            def commandId = sh(
                script: """
                    aws ssm send-command \
                        --document-name "AWS-RunShellScript" \
                        --targets "Key=InstanceIds,Values=${server.instanceId}" \
                        --region "${server.region}" \
                        --comment "Deploy WAR to Tomcat" \
                        --parameters '{"commands":["sudo /usr/jenkins/war_deploy.sh \\"${s3Path}\\""]}' \
                        --query "Command.CommandId" \
                        --output text
                """,
                returnStdout: true
            ).trim()

            echo "SSM CommandId: ${commandId}"

            sh """
                aws ssm wait command-executed \
                    --command-id ${commandId} \
                    --instance-id ${server.instanceId} \
                    --region "${server.region}"
            """

            def output = sh(
                script: """
                    aws ssm get-command-invocation \
                        --command-id ${commandId} \
                        --instance-id ${server.instanceId} \
                        --region "${server.region}" \
                        --query 'StandardOutputContent' \
                        --output text
                """,
                returnStdout: true
            ).trim()

            echo "SSM OUTPUT:\n${output}"
        }

        // --- SAME ACCOUNT → no assume role ---
        if (selectedServer.accountId == env.JENKINS_ACCOUNT_ID) {
            echo "Same AWS account → using Jenkins EC2 IAM role"
            runSsm(selectedServer)
            return
        }

        // --- CROSS ACCOUNT → assume role ---
        echo "Cross-account → assuming role: ${selectedServer.role}"

        withAWS(
            role: "arn:aws:iam::${selectedServer.accountId}:role/${selectedServer.role}",
            roleSessionName: "JenkinsDeploySession",
            region: selectedServer.region
        ) {
            runSsm(selectedServer)
        }
    }
}


def selectServer(boolean isAutoDeploy = false) {
    script {
        def jsonFile = "${WORKSPACE}/tmp/servers.json"
        if (!fileExists(jsonFile)) {
            error("Servers JSON not found at ${jsonFile}. Ensure earlier stage downloaded it.")
        }

        def jsonText = readFile(jsonFile)
        def json = new JsonSlurperClassic().parseText(jsonText)

        // choose which top-level keys to use
        def serversList = []
        if (env.IS_RELEASE.toBoolean()) {
            serversList = (json.staging ?: []) + (json["production-app"] ?: [])
        } else {
            serversList = json.staging ?: []
        }

        if (serversList.isEmpty()) {
            error("No servers available for current branch/release mode. Check servers.json.")
        }

        def serverNames = serversList.collect { it.name }

        def selectedServer = null
        if (isAutoDeploy) {
            selectedServer = serversList.find { it.name == 'Cargo-V2-JDK-17-stage' }
            if (!selectedServer) {
                error("❌ 'staging-app' not found in servers.json for this branch!")
            }
        }
         else {
            def selectedServerName = input(
                id: 'ServerSelect',
                message: 'Select target server:',
                parameters: [
                    choice(name: 'TARGET_SERVER', choices: serverNames.join('\n'), description: 'EC2 Instance')
                ]
            )
            selectedServer = serversList.find { it.name == selectedServerName }
            if (!selectedServer) {
                error("Selected server ${selectedServerName} not found in server list")
            }
        }

        return selectedServer
    }
}

def selectVersion(maxVersions = 15) {
    script {
        def s3Cmd = env.IS_RELEASE.toBoolean() ?
            "aws s3 ls s3://${S3_BUCKET}/${env.PROD_FILEPATH}/${env.SAFE_BRANCH} --region ${AWS_REGION} --recursive" :
            """
            (
                aws s3 ls s3://${S3_BUCKET}/${env.NONPROD_FILEPATH}/${env.SAFE_BRANCH} --region ${AWS_REGION} --recursive | tail -n 10
                aws s3 ls s3://${S3_BUCKET}/${env.PROD_FILEPATH}/release --region ${AWS_REGION} --recursive | tail -n 5
            )
            """

        echo "DEBUG: S3 command -> ${s3Cmd}"
                def versionList = sh(
            script: """
                (${s3Cmd}) |
                grep -E 'chatcore.*\\.jar\$' |
                sort -k1,1 -k2,2 |
                tac |
                awk '{print \$4}' |
                head -n ${maxVersions}
            """,
            returnStdout: true
        ).trim().readLines()

        echo "Available JAR files:\n${versionList.join('\n')}"

        if (!versionList || versionList.isEmpty()) {
            error("No JAR versions found in S3 bucket for branch ${env.BRANCH_NAME}")
        }

        def deployVersion = input(
            id: 'VersionSelect',
            message: 'Select JAR version to deploy:',
            parameters: [
                choice(
                    name: 'SELECTED_VERSION',
                    choices: versionList.join("\n"),
                    description: 'Select JAR file'
                )
            ]
        )


        // return path after bucket name
        return deployVersion.tokenize('/')[1..-1].join('/')
    }
}
// 🧩 Helper: detect who or what triggered the build
def getTriggeredUser() {
    try {
        wrap([$class: 'BuildUser']) {
            return BUILD_USER ?: 'AUTO'
        }
    } catch (err) {
        return 'AUTO'
    }
}

// 🔔 Function: Send Teams notification via Power Automate
def sendTeamsNotification(String status) {
    withCredentials([string(credentialsId: 'teams-webhook-url', variable: 'WEBHOOK')]) {
        def payload = [
            project_name : env.JOB_NAME,
            build_status : status,
            build_number : env.BUILD_NUMBER,
            action_type  : env.ACTION_TYPE ?: "N/A",
            server_name  : env.SELECTED_SERVER ?: "N/A",
            triggered_by : env.TRIGGERED_BY ?: "AUTO",
        ]

        writeFile file: 'payload.json', text: groovy.json.JsonOutput.toJson(payload)

        sh '''
            curl -s -X POST -H "Content-Type: application/json" \
            -d @payload.json "$WEBHOOK"
        '''
    }
}
