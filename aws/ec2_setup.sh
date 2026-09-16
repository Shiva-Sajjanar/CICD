#!/usr/bin/env bash
# ==============================================================================
# AWS EC2 Bootstrap Script (User Data / Setup for Ubuntu 22.04 / 24.04 LTS)
# Prepares the AWS EC2 instance as a Docker host for Jenkins & Ansible deployment
# ==============================================================================

set -e

echo "=== 1. Updating System Packages ==="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "=== 2. Installing Dependencies ==="
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release python3-pip python3-venv

echo "=== 3. Adding Docker GPG Key and Repository ==="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== 4. Installing Docker Engine ==="
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "=== 5. Configuring Docker Service & Permissions ==="
sudo systemctl enable docker
sudo systemctl start docker

# Add ubuntu user to docker group so sudo is not required for docker commands
sudo usermod -aG docker ubuntu

echo "=== 6. Installing Python Docker module for Ansible ==="
sudo apt-get install -y python3-docker || pip3 install docker --break-system-packages

echo "=== EC2 Docker Host Setup Complete! ==="
echo "You can now deploy containers via Ansible or Jenkins."
