#!/bin/bash
# =============================================================================
# deploy-ssm.sh - Deploy code from GitHub to EC2 via AWS SSM
# =============================================================================
# Usage: ./deploy-ssm.sh [options]
# =============================================================================

set -euo pipefail

# Default Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
EC2_INSTANCE_ID="${EC2_INSTANCE_ID:-}"
GITHUB_REPO="${GITHUB_REPO:-}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
DEPLOY_PATH="${DEPLOY_PATH:-/opt/application}"
S3_BUCKET="${S3_BUCKET:-}"
AWS_PROFILE="${AWS_PROFILE:-default}"
SKIP_TESTS="${SKIP_TESTS:-false}"
BACKUP_ENABLED="${BACKUP_ENABLED:-true}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Deploy application from GitHub to EC2 instance via AWS SSM

Required Options:
    -i, --instance-id ID        EC2 Instance ID (e.g., i-0123456789abcdef0)
    -r, --repo URL              GitHub repository URL

Optional Options:
    -b, --branch BRANCH         Git branch to deploy (default: main)
    -p, --path PATH             Deployment path on EC2 (default: /opt/application)
    -s, --s3-bucket BUCKET      S3 bucket for artifact staging
    -R, --region REGION         AWS region (default: us-east-1)
    --profile PROFILE           AWS CLI profile (default: default)
    --skip-tests                Skip test execution
    --no-backup                 Disable backup of current deployment
    -h, --help                  Show this help message

Examples:
    $(basename "$0") -i i-0123456789abcdef0 -r https://github.com/user/repo.git
    $(basename "$0") -i i-abc123 -r https://github.com/user/repo.git -b develop -p /var/www/app
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--instance-id)
                EC2_INSTANCE_ID="$2"
                shift 2
                ;;
            -r|--repo)
                GITHUB_REPO="$2"
                shift 2
                ;;
            -b|--branch)
                GITHUB_BRANCH="$2"
                shift 2
                ;;
            -p|--path)
                DEPLOY_PATH="$2"
                shift 2
                ;;
            -s|--s3-bucket)
                S3_BUCKET="$2"
                shift 2
                ;;
            -R|--region)
                AWS_REGION="$2"
                shift 2
                ;;
            --profile)
                AWS_PROFILE="$2"
                shift 2
                ;;
            --skip-tests)
                SKIP_TESTS="true"
                shift
                ;;
            --no-backup)
                BACKUP_ENABLED="false"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check required tools
    local required_tools=("aws" "git" "tar")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is required but not installed."
            exit 1
        fi
    done
    
    # Validate required parameters
    if [[ -z "$EC2_INSTANCE_ID" ]]; then
        log_error "EC2 Instance ID is required. Use -i or --instance-id"
        exit 1
    fi
    
    if [[ -z "$GITHUB_REPO" ]]; then
        log_error "GitHub repository URL is required. Use -r or --repo"
        exit 1
    fi
    
    # Validate AWS credentials
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        log_error "AWS credentials not configured or invalid for profile: $AWS_PROFILE"
        exit 1
    fi
    
    # Validate EC2 instance exists and SSM is available
    log_info "Checking EC2 instance status..."
    local instance_state
    instance_state=$(aws ec2 describe-instances \
        --instance-ids "$EC2_INSTANCE_ID" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text 2>/dev/null) || {
        log_error "EC2 instance $EC2_INSTANCE_ID not found or no access"
        exit 1
    }
    
    if [[ "$instance_state" != "running" ]]; then
        log_error "EC2 instance is not running. Current state: $instance_state"
        exit 1
    fi
    
    # Check SSM agent status
    log_info "Checking SSM agent connectivity..."
    local ssm_ping
    ssm_ping=$(aws ssm describe-instance-information \
        --filters "Key=InstanceIds,Values=$EC2_INSTANCE_ID" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query 'InstanceInformationList[0].PingStatus' \
        --output text 2>/dev/null)
    
    if [[ "$ssm_ping" != "Online" ]]; then
        log_error "SSM agent is not online. Status: ${ssm_ping:-Not Registered}"
        log_error "Ensure SSM agent is installed and IAM role has AmazonSSMManagedInstanceCore policy"
        exit 1
    fi
    
    log_success "All prerequisites validated"
}

clone_and_build() {
    local build_dir
    build_dir=$(mktemp -d)
    local artifact_name="deploy-$(date +%s).tar.gz"
    
    log_info "Cloning repository: $GITHUB_REPO (branch: $GITHUB_BRANCH)"
    
    # Clone repository
    git clone --depth 1 --branch "$GITHUB_BRANCH" "$GITHUB_REPO" "$build_dir/source"
    
    cd "$build_dir/source"
    
    # Run tests if not skipped
    if [[ "$SKIP_TESTS" == "false" ]]; then
        log_info "Running tests..."
        if [[ -f "package.json" ]]; then
            npm install && npm test
        elif [[ -f "pom.xml" ]]; then
            mvn test
        elif [[ -f "requirements.txt" ]]; then
            python -m pytest
        fi
    fi
    
    # Build application (customize based on your stack)
    log_info "Building application..."
    if [[ -f "package.json" ]]; then
        npm install && npm run build
    elif [[ -f "pom.xml" ]]; then
        mvn clean package -DskipTests
    elif [[ -f "Dockerfile" ]]; then
        docker build -t "app:$(git rev-parse --short HEAD)" .
    fi
    
    # Package for deployment
    log_info "Packaging artifacts..."
    tar -czf "$build_dir/$artifact_name" \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='.env' \
        -C "$build_dir/source" .
    
    echo "$build_dir/$artifact_name"
}

stage_artifact() {
    local artifact_path="$1"
    local s3_key="deployments/$(basename "$artifact_path")"
    
    if [[ -n "$S3_BUCKET" ]]; then
        log_info "Uploading artifact to S3: s3://$S3_BUCKET/$s3_key"
        aws s3 cp "$artifact_path" "s3://$S3_BUCKET/$s3_key" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"
        echo "s3://$S3_BUCKET/$s3_key"
    else
        # Use SSM to transfer file directly (base64 encoded)
        log_info "No S3 bucket provided. Will use direct SSM file transfer."
        echo "direct:$artifact_path"
    fi
}

deploy_via_ssm() {
    local artifact_location="$1"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    log_info "Initiating deployment via SSM..."
    
    # Build deployment script
    local deploy_script
    deploy_script=$(cat <<EOF
#!/bin/bash
set -e

DEPLOY_PATH="$DEPLOY_PATH"
BACKUP_ENABLED="$BACKUP_ENABLED"
TIMESTAMP="$timestamp"
ARTIFACT_LOC="$artifact_location"

echo "=== Deployment Started: \$(date) ==="

# Create directories
sudo mkdir -p "\$DEPLOY_PATH" /opt/backups

# Backup current version
if [[ "\$BACKUP_ENABLED" == "true" ]] && [[ -d "\$DEPLOY_PATH" ]] && [[ "\$(ls -A \$DEPLOY_PATH)" ]]; then
    echo "Creating backup..."
    sudo tar -czf /opt/backups/backup_\${TIMESTAMP}.tar.gz -C "\$DEPLOY_PATH" .
fi

# Download or extract artifact
if [[ "\$ARTIFACT_LOC" == s3://* ]]; then
    echo "Downloading from S3..."
    sudo aws s3 cp "\$ARTIFACT_LOC" /tmp/deploy-artifact.tar.gz
else
    echo "Artifact should be provided via SSM document parameters"
    exit 1
fi

# Deploy
echo "Extracting artifact..."
sudo rm -rf "\${DEPLOY_PATH}"/*
sudo tar -xzf /tmp/deploy-artifact.tar.gz -C "\$DEPLOY_PATH"
sudo chown -R ec2-user:ec2-user "\$DEPLOY_PATH"

# Post-deployment (customize for your application)
echo "Running post-deployment tasks..."
cd "\$DEPLOY_PATH"

# Example: Node.js application
if [[ -f "package.json" ]]; then
    npm install --production
    pm2 restart ecosystem.config.js || pm2 start app.js
fi

# Example: Python application
if [[ -f "requirements.txt" ]]; then
    python3 -m pip install -r requirements.txt
    sudo systemctl restart myapp
fi

# Example: Systemd service
if [[ -f "systemd/myapp.service" ]]; then
    sudo cp systemd/myapp.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable myapp
    sudo systemctl restart myapp
fi

# Cleanup
sudo rm -f /tmp/deploy-artifact.tar.gz

echo "=== Deployment Completed: \$(date) ==="
EOF
)
    
    # Send command via SSM
    local command_id
    command_id=$(aws ssm send-command \
        --instance-ids "$EC2_INSTANCE_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[$deploy_script]" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --output text \
        --query 'Command.CommandId')
    
    log_info "SSM Command ID: $command_id"
    log_info "Waiting for deployment to complete..."
    
    # Wait for completion with timeout
    local max_attempts=60
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        local status
        status=$(aws ssm get-command-invocation \
            --command-id "$command_id" \
            --instance-id "$EC2_INSTANCE_ID" \
            --region "$AWS_REGION" \
            --profile "$AWS_PROFILE" \
            --query 'Status' \
            --output text)
        
        case "$status" in
            Success)
                log_success "Deployment completed successfully!"
                break
                ;;
            Failed|Cancelled|TimedOut)
                log_error "Deployment failed with status: $status"
                # Get error details
                aws ssm get-command-invocation \
                    --command-id "$command_id" \
                    --instance-id "$EC2_INSTANCE_ID" \
                    --region "$AWS_REGION" \
                    --profile "$AWS_PROFILE"
                exit 1
                ;;
            *)
                log_info "Deployment in progress... ($status)"
                sleep 10
                ((attempt++))
                ;;
        esac
    done
    
    if [[ $attempt -eq $max_attempts ]]; then
        log_error "Deployment timed out after $((max_attempts * 10)) seconds"
        exit 1
    fi
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    local verify_script="
        echo '=== Verification ==='
        echo 'Disk Usage:'
        df -h $DEPLOY_PATH | tail -1
        echo ''
        echo 'Deployed Files:'
        ls -la $DEPLOY_PATH
        echo ''
        echo 'Service Status:'
        systemctl status myapp --no-pager || echo 'Service check skipped'
    "
    
    aws ssm send-command \
        --instance-ids "$EC2_INSTANCE_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[$verify_script]" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" > /dev/null
    
    log_success "Verification command sent"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    # Cleanup is handled by trap on EXIT
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    parse_args "$@"
    validate_prerequisites
    
    log_info "Starting deployment pipeline..."
    log_info "Target: $EC2_INSTANCE_ID"
    log_info "Repository: $GITHUB_REPO ($GITHUB_BRANCH)"
    log_info "Deploy Path: $DEPLOY_PATH"
    
    # Build and package
    local artifact_path
    artifact_path=$(clone_and_build)
    log_success "Artifact created: $artifact_path"
    
    # Stage artifact
    local artifact_location
    artifact_location=$(stage_artifact "$artifact_path")
    log_success "Artifact staged: $artifact_location"
    
    # Deploy
    deploy_via_ssm "$artifact_location"
    
    # Verify
    verify_deployment
    
    log_success "Deployment pipeline completed successfully!"
}

# Set trap for cleanup
trap 'rm -rf /tmp/deploy-* 2>/dev/null' EXIT

# Run main
main "$@"