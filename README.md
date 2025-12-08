# 🚀AWS Multi-Node Observability & Automation Stack🚀


A Complete Infrastructure, Monitoring, and Automation Implementation

## 🪄 Project Overview
A minimal DevOps automation project showcasing core **Ansible** functionality, fully automated **AWS infrastructure provisioning using Terraform**, and a complete monitoring & alerting stack powered by **Prometheus**, **Alertmanager**, and **Grafana**.

The project deploys multiple EC2 webservers, configures them automatically using Ansible, and enables full observability through dynamic service discovery and containerized monitoring components.



## 🧰 Technologies Used

| Category | Technology |
| --- | --- |
| Infrastructure Provisioning | Terraform |
| Containerization | Docker & Docker Compose |
| Infrastructure Provisioning | Terraform |
| Configuration Management | Ansible|
| Monitoring | Prometheus |
| Alerting | Alertmanager |
| Dashboard Visualization | Grafana |


	
	
	
## ⭐ Project Features
### 🔍 Bash Script (deploy.sh)

A simple verification script that checks:
- Installed dependencies
- Docker, Compose, Terraform, and Ansible


### 🛠️ Terraform (Infrastructure as Code)
**Terraform Highlights**

- Modular structure for clean provisioning
- Modules:
    - VPC
    - Security Groups
    - Control Node
    - Webserver Nodes
- Secure Security Groups:
  - Webservers only accept access from the Control Node

- Automated EC2 provisioning with user-data scripts

- SSH keys embedded and auto-managed

### 🐳 Docker (Containerized Monitoring)
**Control Node (Docker Compose)**
- Prometheus
- Alertmanager
- Grafana

**Webserver Nodes (Docker Compose)**
- Node Exporter
- cAdvisor

### 📈 Prometheus
**Prometheus Features**
- EC2 Service Discovery
  Automatically detects new EC2 instances → No manual editing of targets

- Labels include:
  - EC2 instance name
  - Private IP
  - Docker container name

- Custom alerting rules in rules.yml

### 📊 Grafana Dashboards
Pre-built dashboards:
- Node Exporter Dashboard
- Docker Containers Dashboard

### ⚙️ Ansible Features Demonstrated
1. Dynamic Inventory Management using aws_ec2 plugin 
2. Variables
  - Group variables
  - Host variables
  - Dynamic facts from remote machines
3. Modules Used
  - *apt*  — Package installation
  - *systemd* — Service management
  -  *file* — Directory & permissions
  - *template* — Jinja2 templating
  - *uri* — HTTP checks
4. Templates
  - Jinja2 templates with facts + dynamic variables
  - Custom HTML system info page
5. Handlers
  - Automated service restarts when config changes
6. Tags
  - Selective execution of tasks
7. Facts
  - Used to dynamically update templates
8. Conditionals
  - Used for OS checks, validation, and dynamic logic
9. Error Handling
  - ignore_errors: yes for optional tasks

### 📂 Project Structure
```
DevOps-Project
├── Ansible
│   ├── ansible.cfg
│   ├── inventory
│   │   ├── aws_ec2.yml
│   │   ├── group_vars
│   │   │   └── webservers.yml
│   │   └── inventory.ini
│   └── playbooks
│       ├── cpu-load-test.yml
│       ├── deploy-webservers.yml
│       ├── node-exporter-cadvisor-installation.yml
│       └── templates
│           ├── index.html.j2
│           └── systeminfo.html.j2
├── Monitoring
│   ├── alertmanager
│   │   └── alertmanager.yml
│   ├── docker-compose.yml
│   └── prometheus
│       ├── prometheus.yml
│       └── rules.yml
├── README.md
├── Terraform
│   ├── main.tf
│   ├── modules
│   │   ├── Controlnode
│   │   │   ├── controlnode.sh
│   │   │   ├── main.tf
│   │   │   ├── output.tf
│   │   │   └── variables.tf
│   │   ├── SecurityGroups
│   │   │   ├── main.tf
│   │   │   ├── output.tf
│   │   │   └── variables.tf
│   │   ├── VPC
│   │   │   ├── main.tf
│   │   │   ├── output.tf
│   │   │   └── variables.tf
│   │   └── Webserver
│   │       ├── main.tf
│   │       ├── output.tf
│   │       ├── variables.tf
│   │       └── webserver.sh
│   ├── output.tf
│   ├── provider.tf
│   ├── ssh
│   │   ├── deployer_key
│   │   └── deployer_key.pub
│   ├── terraform.tfstate
│   ├── terraform.tfstate.backup
│   └── variables.tf
├── Webservers
│   └── node-exporter-cadvisor-installation.yml
├── deploy.sh
```

---


### ⚠️ Challenges Faced
- Implementing Dynamic Inventory for Ansible for the first time
- Configuring Prometheus EC2 Service Discovery
- Jinja2 templating with dynamic facts
- Coordinating interactions between Terraform → Ansible → Docker

### 🚀 Future Work
- Integrate CI/CD pipelines
