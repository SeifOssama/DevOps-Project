#!/bin/bash

#Hold Kernel updates
apt-mark hold $(uname -r)


# ----------------------------
# Phase 1: System update
# ----------------------------
apt update -y

# ----------------------------
# Phase 2: Docker Installation
# ----------------------------

# Install Docker & Docker Compose
# Add Docker's official GPG key:
apt install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update

apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker 
systemctl enable docker

getent group docker || groupadd docker

usermod -aG docker ubuntu

newgrp docker


echo "====== Docker Installed Successfully! ======"

# ----------------------------
# Phase 3: Ansible Installation 
# ----------------------------
apt install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt install -y ansible python3 python3-pip unzip 

systemctl  daemon-reload

# Install Python packages idempotently
pip3 install --upgrade pip
pip3 install --upgrade boto3 botocore
ansible-galaxy collection install amazon.aws
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
aws --version
rm -rf awscliv2.zip aws


# Clone the repository
cd /home/ubuntu
git clone https://github.com/SeifOssama/DevOps-Project
chown -R ubuntu:ubuntu DevOps-Project
