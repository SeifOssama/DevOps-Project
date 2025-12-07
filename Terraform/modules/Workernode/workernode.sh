#!/bin/bash

#Hold Kernel updates
apt-mark hold $(uname -r)


# Install Apache and python3
apt install -y apache2  python3 

systemctl  daemon-reload