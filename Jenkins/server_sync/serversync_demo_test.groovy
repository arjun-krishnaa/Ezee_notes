pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        S3_BUCKET  = '28-feb-demo'
        S3_KEY     = 'jenkins_server_file/servers.json'
        FILE_PATH  = "${WORKSPACE}/servers.json"
        LOCAL_DIR  = "${WORKSPACE}/json-to-upload"
        ROLE_ARN   = "arn:aws:iam::590182060736:instance-profile/jenkins_role"
    }

    stages {
        stage('Write JSON') {
            steps {
                script {
                    def jsonContent = '''{
  "staging": [
    {
      "name": "staging-app",
      "instanceId": "i-03711b2a6f63002db",
      "accountId": "590182060736",
      "region": "ap-south-1",
      "role": "jenkins_role",
      //"newmanEnv": "srm-stage-environment.json",
      //"approver": "venkat-ezee"
    },
    
  ]
}'''
                    writeFile file: env.FILE_PATH, text: jsonContent
                }
            }
        }

        stage('Prepare JSON for Upload') {
            steps {
                script {
                    sh "mkdir -p '${env.LOCAL_DIR}'"
                    sh "cp '${env.FILE_PATH}' '${env.LOCAL_DIR}/servers.json'"
                    echo "📄 Copied JSON to ${env.LOCAL_DIR}/servers.json"
                }
            }
        }

        stage('Upload to S3') {
            steps {
                script {
                    def versionKey = "ezeebits/server/versions/servers-${env.BUILD_ID}.json"

                    sh """
                        aws s3 cp '${env.LOCAL_DIR}/servers.json' 's3://${env.S3_BUCKET}/${env.S3_KEY}'
                        aws s3 cp '${env.LOCAL_DIR}/servers.json' 's3://${env.S3_BUCKET}/${versionKey}'
                    """

                    echo "✅ Uploaded to: s3://${env.S3_BUCKET}/${env.S3_KEY}"
                    echo "🕒 Versioned copy: s3://${env.S3_BUCKET}/${versionKey}"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully."
        }
        failure {
            echo "❌ Pipeline failed."
        }
    }
}