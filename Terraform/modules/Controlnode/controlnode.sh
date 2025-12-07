#!/bin/bash

#Hold Kernel updates
apt-mark hold linux-image-generic linux-headers-generic

# Install Apache and PHP
apt update -y && apt upgrade -y
apt install -y apache2 php python3 ansible boto3 botocore

# Start and enable Apache
systemctl start apache2
systemctl enable apache2

# Fetch instance metadata
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "Not Assigned")
LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Create a PHP script with metadata
cat <<EOP > /var/www/html/index.php
<!DOCTYPE html>
<html>
<head>
    <title>Instance Details</title>
</head>
<body>
   <div align="center">
	<h1> Made by Seif Yakout </h1>
	<h1>Welcome to the Control Node Instance</h1>
    <h2>Instance Details:</h2>
    <ul>
        <li>Availability Zone: <?php echo '$AZ'; ?></li>
        <li>Instance ID: <?php echo '$INSTANCE_ID'; ?></li>
        <li>Public IP: <?php echo '$PUBLIC_IP'; ?></li>
        <li>Local IP: <?php echo '$LOCAL_IP'; ?></li>
    </ul>
    </div>
</body>
</html>
EOP

# Set permissions
chmod 644 /var/www/html/index.php

# Restart Apache
systemctl restart apache2
systemctl  daemon-reload

# Clone the repository
cd /home/ubuntu
git clone https://github.com/SeifOssama/DevOps-Project