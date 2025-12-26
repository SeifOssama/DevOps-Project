#!/bin/bash

# Minimal bootstrap script for Webservers
# Heavy lifting done by Ansible from GitHub Actions

# Update package lists
apt-get update -y

# Install basic utilities
apt-get install -y \
  ca-certificates \
  curl \
  wget \
  python3 \
  python3-pip

# Mark bootstrap complete
echo "BOOTSTRAP_COMPLETE" > /tmp/bootstrap_status
echo "Bootstrap completed at $(date)" >> /tmp/bootstrap_status
echo "Webserver ready for Ansible configuration" >> /tmp/bootstrap_status

# That's it! Ansible from GitHub Actions will handle:
# - Apache2 installation and configuration
# - Docker installation for exporters
# - Node Exporter and cAdvisor deployment
# - Website template rendering
