pipeline {
    agent any

    options {
        timestamps()
        disableResume()   // 🔥 prevent broken resume after Jenkins restart
    }

    environment {
        TOOLS_DIR  = "${WORKSPACE}/tools"
        MAVEN_REPO = "${WORKSPACE}/.m2"
        GIT_REPO   = 'https://github.com/arjun-krishnaa/probe.git'
        BRANCH     = 'master'
    }

    stages {

        stage('Checkout Code') {
            steps {
                retry(2) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'github-classic-token-arjun',
                            usernameVariable: 'GIT_USER',
                            passwordVariable: 'GIT_TOKEN'
                        )
                    ]) {
                        sh '''
                            set -e
                            rm -rf probe

                            echo "📥 Cloning repository..."
                            git clone -b master https://$GIT_USER:$GIT_TOKEN@github.com/arjun-krishnaa/probe.git
                        '''
                    }
                }
            }
        }

        // 🔥 Setup Java 21 + Maven 3.9.12 (runtime only)
        stage('Setup Runtime') {
            steps {
                retry(2) {
                    sh '''
                    set -e

                    mkdir -p "$TOOLS_DIR"

                    JAVA_HOME="$TOOLS_DIR/java"
                    MAVEN_HOME="$TOOLS_DIR/maven"

                    ARCH=$(uname -m)
                    echo "Detected architecture: $ARCH"

                    # -------------------------
                    # Install Java 21
                    # -------------------------
                    if [ "$ARCH" = "aarch64" ]; then
                      JDK_URL="https://corretto.aws/downloads/latest/amazon-corretto-21-aarch64-linux-jdk.tar.gz"
                    else
                      JDK_URL="https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz"
                    fi

                    if [ ! -d "$JAVA_HOME" ]; then
                      echo "⬇️ Installing Java 21..."
                      curl -f -L -o /tmp/jdk.tar.gz "$JDK_URL"
                      tar -xzf /tmp/jdk.tar.gz -C "$TOOLS_DIR"
                      mv "$TOOLS_DIR"/amazon-corretto-21* "$JAVA_HOME"
                    fi

                    # -------------------------
                    # Install Maven 3.9.12
                    # -------------------------
                    MAVEN_URL="https://archive.apache.org/dist/maven/maven-3/3.9.12/binaries/apache-maven-3.9.12-bin.tar.gz"

                    if [ ! -d "$MAVEN_HOME" ]; then
                      echo "⬇️ Installing Maven..."
                      curl -f -L -o /tmp/maven.tar.gz "$MAVEN_URL"

                      # Validate download
                      if ! file /tmp/maven.tar.gz | grep -q gzip; then
                        echo "❌ Invalid Maven download"
                        exit 1
                      fi

                      tar -xzf /tmp/maven.tar.gz -C "$TOOLS_DIR"
                      mv "$TOOLS_DIR"/apache-maven-3.9.12 "$MAVEN_HOME"
                    fi

                    export JAVA_HOME="$JAVA_HOME"
                    export MAVEN_HOME="$MAVEN_HOME"
                    export PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH"

                    echo "✅ Java Version:"
                    java -version

                    echo "✅ Maven Version:"
                    mvn -v
                    '''
                }
            }
        }

        stage('Build PSI Probe') {
            steps {
                retry(2) {
                    dir('probe') {
                        sh '''
                        set -e

                        export JAVA_HOME="${WORKSPACE}/tools/java"
                        export MAVEN_HOME="${WORKSPACE}/tools/maven"
                        export PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH"

                        echo "🚀 Building PSI Probe..."

                        mvn clean install \
                          -Dmaven.repo.local=${WORKSPACE}/.m2 \
                          -DskipTests=true \
                          -Dbuild.branch=master \
                          -Dbuild.number=${BUILD_NUMBER}
                        '''
                    }
                }
            }
        }

        stage('Archive Artifact') {
            steps {
                archiveArtifacts artifacts: 'probe/**/target/*.war', fingerprint: true
            }
        }
    }

    post {
        success {
            echo "✅ Build completed successfully"
        }
        failure {
            echo "❌ Build failed — check logs"
        }
        always {
            echo "🧹 Cleaning runtime..."
            sh 'rm -rf "${WORKSPACE}/tools"'
        }
    }
}