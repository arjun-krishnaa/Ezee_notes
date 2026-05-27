pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        S3_BUCKET  = '28-feb-demo'
        S3_KEY     = ''
        FILE_PATH  = "${WORKSPACE}/servers.json"
        LOCAL_DIR  = "${WORKSPACE}/json-to-upload"
        ROLE_ARN   = "arn:aws:iam::590182060736:instance-profile/jenkins_role"

        // Teams Webhook URL (Store in Jenkins Credentials)
        TEAMS_WEBHOOK = credentials('teams-webhook-url')
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
      "role": "jenkins_role"
    }
  ]
}'''

                    writeFile file: env.FILE_PATH, text: jsonContent

                    echo "✅ JSON file created successfully"
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
                        aws s3 cp '${env.LOCAL_DIR}/servers.json' 's3://${env.S3_BUCKET}/${env.S3_KEY}' --region ${env.AWS_REGION}

                        aws s3 cp '${env.LOCAL_DIR}/servers.json' 's3://${env.S3_BUCKET}/${versionKey}' --region ${env.AWS_REGION}
                    """

                    echo "✅ Uploaded to: s3://${env.S3_BUCKET}/${env.S3_KEY}"
                    echo "🕒 Versioned copy: s3://${env.S3_BUCKET}/${versionKey}"
                }
            }
        }
    }

    post {

        success {
            script {

                def successMessage = """
                {
                  "@type": "MessageCard",
                  "@context": "http://schema.org/extensions",
                  "themeColor": "00FF00",
                  "summary": "Jenkins Pipeline Success",
                  "sections": [{
                    "activityTitle": "✅ Jenkins Pipeline Success",
                    "facts": [
                      {
                        "name": "Job Name",
                        "value": "${env.JOB_NAME}"
                      },
                      {
                        "name": "Build Number",
                        "value": "${env.BUILD_NUMBER}"
                      },
                      {
                        "name": "Build URL",
                        "value": "${env.BUILD_URL}"
                      },
                      {
                        "name": "S3 Bucket",
                        "value": "${env.S3_BUCKET}/${env.S3_KEY}"
                      }
                    ],
                    "markdown": true
                  }]
                }
                """

                sh """
                    curl -H 'Content-Type: application/json' \
                    -d '${successMessage}' \
                    ${TEAMS_WEBHOOK}
                """

                echo "✅ Teams success notification sent."
            }
        }

        failure {
            script {

                def failureMessage = """
                {
                  "@type": "MessageCard",
                  "@context": "http://schema.org/extensions",
                  "themeColor": "FF0000",
                  "summary": "Jenkins Pipeline Failed",
                  "sections": [{
                    "activityTitle": "❌ Jenkins Pipeline Failed",
                    "facts": [
                      {
                        "name": "Job Name",
                        "value": "${env.JOB_NAME}"
                      },
                      {
                        "name": "Build Number",
                        "value": "${env.BUILD_NUMBER}"
                      },
                      {
                        "name": "Build URL",
                        "value": "${env.BUILD_URL}"
                      }
                    ],
                    "markdown": true
                  }]
                }
                """

                sh """
                    curl -H 'Content-Type: application/json' \
                    -d '${failureMessage}' \
                    ${TEAMS_WEBHOOK}
                """

                echo "❌ Teams failure notification sent."
            }
        }

        always {
            cleanWs()
        }
    }
}