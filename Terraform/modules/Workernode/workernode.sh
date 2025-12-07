#!/bin/bash

#Hold Kernel updates
apt-mark hold linux-image-generic linux-headers-generic

# Install Apache and python3
apt update -y && apt upgrade -y
apt install -y apache2  python3 

systemctl  daemon-reload