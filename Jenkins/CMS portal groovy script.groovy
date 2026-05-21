pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-2"
        INSTANCE_ID = "i-0407a8149081a22e7"
        ROLE_ARN = "arn:aws:iam::259640624578:role/DeployerJenkinsSSMExecutionRole"
    }

    stages {
        stage('Deploy via SSM') {
            steps {
                script {
                    echo "Executing cms-portal-update.sh via SSM"

                    withAWS(role: "${ROLE_ARN}", region: "${AWS_REGION}") {

                        def commandId = sh(
                            script: """
                            aws ssm send-command \
                              --targets Key=InstanceIds,Values=${INSTANCE_ID} \
                              --document-name "AWS-RunShellScript" \
                              --comment "Run cms update" \
                              --parameters 'commands=["sudo /usr/jenkins/cms-portal-update.sh"]' \
                              --region ${AWS_REGION} \
                              --query "Command.CommandId" \
                              --output text
                            """,
                            returnStdout: true
                        ).trim()

                        echo "SSM Command ID: ${commandId}"

                        // Wait for execution
                        sh """
                        aws ssm wait command-executed \
                          --command-id ${commandId} \
                          --instance-id ${INSTANCE_ID} \
                          --region ${AWS_REGION}
                        """

                        // Get output
                        def output = sh(
                            script: """
                            aws ssm get-command-invocation \
                              --command-id ${commandId} \
                              --instance-id ${INSTANCE_ID} \
                              --region ${AWS_REGION} \
                              --output json
                            """,
                            returnStdout: true
                        )

                        echo "Command Output: ${output}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful"
        }
        failure {
            echo "❌ Deployment failed"
        }
    }
}