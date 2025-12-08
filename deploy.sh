#!/bin/bash

figlet -f big "YAKOUT"|lolcat -f




echo -e "
\033[96m===============================================================\033[0m
\033[1;31m               🚀 DevOps Automation Project 🚀\033[0m
✨ A compact demonstration of real DevOps automation workflows.
---------------------------------------------------------------
   • Installs Docker, Docker Compose & Ansible
   • Deploys Monitoring Stack (Prometheus + Grafana)
   • Deploys Web Servers + Exporters + cAdvisor

\033[1;31mAnsible Usage:\033[0m
=============
   • Dynamic Inventory (AWS EC2 discovery)
   • Dynamic Prometheus Targets (EC2 SD)
   • Inventory groups & variables
   • Modules: apt, systemd, file, template, uri
   • Jinja2 templating & handlers
   • Tags, conditionals, facts, and error handling
---------------------------------------------------------------
             Author: Seif Yakout | Version: 1.0
\033[96m===============================================================\033[0m
"
set -euo pipefail


errors=0

printf "
\e[96m##################################################\e[0m
   \e[31m\e[1mPhase 1: Docker Installation Check \e[0m \e[31m \e[0m
\e[96m##################################################\e[0m
"

# Docker check
if command -v docker &>/dev/null; then
    echo "✅ Docker is installed: $(docker --version)" | lolcat -f
else
    echo "ERROR: Docker is not installed!"
    errors=$((errors+1))
fi

# Docker check
if command -v docker &>/dev/null; then
    echo "✅ Docker is installed: $(docker --version)" | lolcat -f
else
    echo "ERROR: Docker is not installed!"
    errors=$((errors+1))
fi

# Docker Compose check
if docker compose version &>/dev/null; then
    echo "✅ Docker Compose is installed: $(docker compose version | head -n1)" |lolcat -f
else
    echo "ERROR: Docker Compose is not installed!"
    errors=$((errors+1))
fi


printf "
\e[96m##################################################\e[0m
   \e[31m\e[1mPhase 2: Python Installation Check \e[0m \e[31m \e[0m
\e[96m##################################################\e[0m
"
# Python3 check
if command -v python3 &>/dev/null; then
    echo "✅ Python3 is installed: $(python3 --version)" | lolcat -f
else
    echo "ERROR: Python3 is not installed!"
    errors=$((errors+1))
fi

printf "
\e[96m##################################################\e[0m
   \e[31m\e[1mPhase 3: Ansible Installation Check \e[0m \e[31m \e[0m
\e[96m##################################################\e[0m
"
# Ansible check
if command -v ansible &>/dev/null; then
    echo "✅ Ansible is installed: $(ansible --version | head -n1)" | lolcat -f
else
    echo "ERROR: Ansible is not installed!"
    errors=$((errors+1))
fi


echo ""
echo ""

# Summary
if [ $errors -eq 0 ]; then
    echo "All checks passed successfully!🎉" | lolcat -f
else
    echo "⚠️ There were $errors issues detected." | lolcat -f
fi

printf "
\e[96m##################################################\e[0m
   \e[31m\e[1mVerification Completed \e[0m \e[31m \e[0m
\e[96m##################################################\e[0m
"
