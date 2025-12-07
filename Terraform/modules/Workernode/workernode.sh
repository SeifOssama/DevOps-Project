#!/bin/bash

apt update -y && apt upgrade -y


# create docker group
groupadd docker
usermod -aG docker $USER
newgrp docker


# Add Docker's official GPG key:
apt install -y ca-certificates curl
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


apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker
systemctl enable docker

# create docker group
groupadd docker
usermod -aG docker $USER
newgrp docker

docker run hello-world

echo "Docker Downloaded Successfully ..."

apt install -y docker-compose

apt install -y python3

systemctl  daemon-reload