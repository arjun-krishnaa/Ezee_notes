pipeline {
    agent any

    environment {
        GIT_REPO = "https://github.com/JavakarBits/ezeeBus.git"
        AWS_REGION = "ap-south-2"
        INSTANCE_ID = "i-0c73637bc3642b810"
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'for-staging', description: 'Branch to deploy')
    }

    stages {

        stage('Collect Inputs') {
            steps {
                script {
                    echo "Triggered by: ${env.BUILD_USER}"
                }
            }
        }

        stage('Validate Branch') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'git-creds',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh '''
                    git ls-remote --heads https://$GIT_USER:$GIT_TOKEN@github.com/JavakarBits/ezeeBus.git ${BRANCH} | grep ${BRANCH}
                    '''
                }
                echo "✅ Branch ${params.BRANCH} exists"
            }
        }

        stage('Select Target Server') {
            steps {
                script {
                    sh '''
                    mkdir -p tmp
                    aws s3 cp s3://ezin-jenkins-cicd/ezeebits/server/servers.json tmp/servers.json
                    '''

                    def servers = readJSON file: 'tmp/servers.json'

                    def selected = input(
                        message: 'Select server',
                        parameters: [
                            choice(
                                name: 'SERVER',
                                choices: servers*.name.join('\n'),
                                description: 'Choose target server'
                            )
                        ]
                    )

                    env.SELECTED_SERVER = selected
                    echo "Selected server: ${selected}"
                }
            }
        }

        stage('Deploy via SSM') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    script {

                        def commandId = sh(
                            script: """
                            aws ssm send-command \
                              --targets Key=InstanceIds,Values=${INSTANCE_ID} \
                              --document-name AWS-RunShellScript \
                              --parameters 'commands=["sudo /usr/jenkins/deploy-bits-console.sh ${params.BRANCH}"]' \
                              --query Command.CommandId \
                              --output text
                            """,
                            returnStdout: true
                        ).trim()

                        echo "SSM Command ID: ${commandId}"

                        sh "aws ssm wait command-executed --command-id ${commandId} --instance-id ${INSTANCE_ID}"

                        sh """
                        aws ssm get-command-invocation \
                          --command-id ${commandId} \
                          --instance-id ${INSTANCE_ID}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Build finished | Server=${env.SELECTED_SERVER} | Branch=${params.BRANCH}"
        }
    }
}