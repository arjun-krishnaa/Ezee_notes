#!/bin/bash

# Update system
yum update -y

mkdir -p /home/ec2-user/java

cd /home/ec2-user/java

wget https://corretto.aws/downloads/latest/amazon-corretto-17-x64-linux-jdk.rpm

dnf install -y amazon-corretto-17-x64-linux-jdk.rpm

# Install Java 17
#amazon-linux-extras install java-openjdk17 -y || yum install -y java-17-openjdk

# Add Jenkins repository
wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
yum install -y jenkins

# Start and enable Jenkins
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

# Create 2GB swap memory
fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048

chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Make swap permanent
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

# Verify
free -h

# Jenkins status
systemctl status jenkins