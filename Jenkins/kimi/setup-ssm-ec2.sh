#!/bin/bash
# =============================================================================
# setup-ssm-ec2.sh - Prepare EC2 instance for SSM-based deployments
# =============================================================================
# Run this on the target EC2 instance
# =============================================================================

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Update system
log "Updating system packages..."
sudo yum update -y || sudo apt-get update -y

# Install SSM Agent (Amazon Linux 2/2023 already has it, but ensure latest)
log "Installing/updating SSM Agent..."
if [[ -f /etc/system-release ]]; then
    # Amazon Linux
    sudo yum install -y amazon-ssm-agent
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
else
    # Ubuntu/Debian
    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
    sudo dpkg -i amazon-ssm-agent.deb
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
fi

# Install AWS CLI v2
log "Installing AWS CLI..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Create deployment directories
log "Creating deployment directories..."
sudo mkdir -p /opt/application /opt/backups /opt/scripts
sudo chown -R ec2-user:ec2-user /opt/application /opt/backups

# Install additional tools based on application type
log "Installing common deployment dependencies..."

# Node.js (optional)
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs || sudo apt-get install -y nodejs
fi

# PM2 for process management (optional)
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
fi

# Docker (optional)
if ! command -v docker &> /dev/null; then
    sudo yum install -y docker || sudo apt-get install -y docker.io
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
fi

# Verify SSM agent status
log "Verifying SSM Agent status..."
sudo systemctl status amazon-ssm-agent --no-pager

log "EC2 instance setup complete!"
log "Ensure the instance has IAM role with AmazonSSMManagedInstanceCore policy attached."