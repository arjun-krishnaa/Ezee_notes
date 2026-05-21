// Jenkinsfile - GitHub to EC2 via SSM
pipeline {
    agent any
    
    environment {
        // AWS Configuration
        AWS_REGION = 'ap-south-1'                    // Change to your region
        AWS_CREDENTIALS_ID = 'aws-credentials'      // Jenkins credential ID for AWS
        
        // GitHub Configuration
        GITHUB_REPO = 'https://github.com/arjun-krishnaa/Ezee_notes.git'
        GITHUB_CREDENTIALS_ID = 'FINE_GRAIN'      // Jenkins credential ID for GitHub
        
        // Target EC2 Configuration
        EC2_INSTANCE_ID = 'i-0ba0467f8f682e4f8'     // Your EC2 instance ID
        DEPLOY_PATH = '/home/ec2-user/jenkins/demo/bus'                  // Deployment path on EC2
        
        // Build artifacts
        ARTIFACT_NAME = 'app-release.tar.gz'
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                git(
                    url: "${GITHUB_REPO}",
                    credentialsId: "${GITHUB_CREDENTIALS_ID}",
                    branch: 'main'
                )
                sh 'git log --oneline -5'
            }
        }
        
        stage('Build & Test') {
            steps {
                sh '''
                    echo "Running build steps..."
                    # Add your build commands here
                    # npm install && npm run build
                    # or: mvn clean package
                    # or: docker build -t myapp:${BUILD_NUMBER} .
                '''
            }
        }
        
        stage('Package Artifacts') {
            steps {
                sh """
                    echo "Packaging application..."
                    tar -czf ${ARTIFACT_NAME} --exclude='.git' --exclude='node_modules' .
                    ls -lh ${ARTIFACT_NAME}
                """
            }
        }
        
        stage('Upload to S3 (Staging Area)') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    sh """
                        echo "Uploading artifact to S3 staging bucket..."
                        aws s3 cp ${ARTIFACT_NAME} s3://your-deployment-bucket/builds/${BUILD_NUMBER}/${ARTIFACT_NAME}
                    """
                }
            }
        }
        
        stage('Deploy to EC2 via SSM') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    script {
                        // Method 1: Using AWS CLI SSM send-command
                        deployViaSSMCommand()
                        
                        // Method 2: Using SSM Session (alternative)
                        // deployViaSSMSession()
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_REGION}") {
                    sh """
                        echo "Verifying deployment health..."
                        aws ssm send-command \
                            --instance-ids "${EC2_INSTANCE_ID}" \
                            --document-name "AWS-RunShellScript" \
                            --parameters commands=["systemctl status myapp || true","curl -sf http://localhost:8080/health || echo 'Health check not configured'"] \
                            --region ${AWS_REGION}
                    """
                }
            }
        }
    }
    
    post {
        always {
            sh 'rm -f ${ARTIFACT_NAME} || true'
            cleanWs()
        }
        success {
            echo "Deployment successful! Build #${BUILD_NUMBER}"
        }
        failure {
            echo "Deployment failed! Check logs."
            // Add notification: Slack, Email, etc.
        }
    }
}

// ============== SSM Deployment Methods ==============

def deployViaSSMCommand() {
    // Method 1: AWS-RunShellScript Document
    // Downloads artifact from S3 and deploys on EC2
    
    def deployScript = """
        set -e
        
        # Variables
        BUILD_NUM='${env.BUILD_NUMBER}'
        BUCKET="your-deployment-bucket"
        APP_NAME="myapp"
        DEPLOY_DIR="/home/ec2-user/jenkins/bus"
        BACKUP_DIR="/opt/backups"
        TIMESTAMP=\\$(date +%Y%m%d_%H%M%S)
        
        echo "=== Starting Deployment: Build #\\${BUILD_NUM} ==="
        
        # Create necessary directories
        sudo mkdir -p \\${DEPLOY_DIR} \\${BACKUP_DIR}
        
        # Backup current version
        if [ -d "\\${DEPLOY_DIR}" ] && [ "\\$(ls -A \\${DEPLOY_DIR})" ]; then
            echo "Creating backup..."
            sudo tar -czf \\${BACKUP_DIR}/\\${APP_NAME}_\\${TIMESTAMP}.tar.gz -C \\${DEPLOY_DIR} .
        fi
        
        # Download new artifact from S3
        echo "Downloading artifact from S3..."
        sudo aws s3 cp s3://\\${BUCKET}/builds/\\${BUILD_NUM}/${ARTIFACT_NAME} /tmp/\\${BUILD_NUM}_${ARTIFACT_NAME}
        
        # Extract to deployment directory
        echo "Extracting artifact..."
        sudo rm -rf \\${DEPLOY_DIR}/*
        sudo tar -xzf /tmp/\\${BUILD_NUM}_${ARTIFACT_NAME} -C \\${DEPLOY_DIR}
        
        # Set proper permissions
        sudo chown -R ec2-user:ec2-user \\${DEPLOY_DIR}
        
        # Run post-deployment scripts
        echo "Running post-deployment..."
        cd \\${DEPLOY_DIR}
        
        # Example: Install dependencies and restart service
        # npm install --production
        # sudo systemctl restart myapp
        
        # Cleanup
        sudo rm -f /tmp/\\${BUILD_NUM}_${ARTIFACT_NAME}
        
        echo "=== Deployment Complete ==="
    """.stripIndent()
    
    // Execute via SSM
    sh """
        COMMAND_ID=\$(aws ssm send-command \
            --instance-ids "${EC2_INSTANCE_ID}" \
            --document-name "AWS-RunShellScript" \
            --parameters "commands=[${deployScript}]" \
            --region ${AWS_REGION} \
            --output text \
            --query 'Command.CommandId')
        
        echo "SSM Command ID: \${COMMAND_ID}"
        
        # Wait for completion
        echo "Waiting for deployment to complete..."
        aws ssm wait command-executed \
            --command-id "\${COMMAND_ID}" \
            --instance-id "${EC2_INSTANCE_ID}" \
            --region ${AWS_REGION}
        
        # Get execution results
        echo "Deployment output:"
        aws ssm get-command-invocation \
            --command-id "\${COMMAND_ID}" \
            --instance-id "${EC2_INSTANCE_ID}" \
            --region ${AWS_REGION}
    """
}

def deployViaSSMSession() {
    // Method 2: Using SSM Session for interactive-like deployment
    // Useful for complex deployments requiring multiple steps
    
    sh """
        # Start SSM session and execute deployment
        aws ssm start-session \
            --target "${EC2_INSTANCE_ID}" \
            --region ${AWS_REGION} \
            --document-name AWS-StartInteractiveCommand \
            --parameters command="bash -c 'cd ${DEPLOY_PATH} && echo Deploying build ${BUILD_NUMBER}'"
    """
}