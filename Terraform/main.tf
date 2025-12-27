# === ROOT main.tf === #

# ---------------------------------------------------------------------
# Calling the VPC Module
# ---------------------------------------------------------------------
module "vpc" {
  source              = "./modules/VPC"
  vpc_cidr_block      = var.vpc_cidr_block
  public-subnet1_cidr = var.public-subnet1_cidr
  availability_zone_a = var.availability_zone_a

}


# ---------------------------------------------------------------------
# Calling the Security Group Modules
# ---------------------------------------------------------------------

module "controlnode_sg" {
  source      = "./modules/SecurityGroups"
  vpc-ID      = module.vpc.vpc_id
  name        = "controlnode_sg"
  description = "This is Monitoring Node Security Group"
  ingress_rules = {
    icmp = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = -1
      ip_protocol                  = "icmp"
      to_port                      = -1
    }
    ssh = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 22
      ip_protocol                  = "tcp"
      to_port                      = 22
    }
    http = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 80
      ip_protocol                  = "tcp"
      to_port                      = 80
    }
    prometheus = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 9090
      ip_protocol                  = "tcp"
      to_port                      = 9090
    }
    alertmanager = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 9093
      ip_protocol                  = "tcp"
      to_port                      = 9093
    }
    grafana = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 3000
      ip_protocol                  = "tcp"
      to_port                      = 3000
    }


  }
  tags = {
    Name = "MonitoringNode-SG"
  }
}


module "workernode_sg" {
  source      = "./modules/SecurityGroups"
  vpc-ID      = module.vpc.vpc_id
  name        = "workernode_sg"
  description = "This is Worker Node Security Group"
  ingress_rules = {
    icmp = {
      cidr_ipv4                    = null
      referenced_security_group_id = module.controlnode_sg.securitygroup_id
      from_port                    = -1
      ip_protocol                  = "icmp"
      to_port                      = -1
    }
    ssh = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 22
      ip_protocol                  = "tcp"
      to_port                      = 22
    }
    http = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 80
      ip_protocol                  = "tcp"
      to_port                      = 80
    }
    node-exporter = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 9100
      ip_protocol                  = "tcp"
      to_port                      = 9100
    }
    cadvisor = {
      cidr_ipv4                    = "0.0.0.0/0"
      referenced_security_group_id = null
      from_port                    = 8080
      ip_protocol                  = "tcp"
      to_port                      = 8080
    }
  }
  tags = {
    Name = "WorkerNode-SG"
  }
}

# === Control & Worker Nodes Setup Script ===#
module "controlnode" {
  source         = "./modules/Controlnode"
  public-subnet1 = module.vpc.public_subnet1_id
  controlnode_sg = module.controlnode_sg.securitygroup_id
  key_name       = aws_key_pair.deployer.key_name
}


module "webserver" {
  source         = "./modules/Workernode"
  count          = 2
  name           = "webserver${count.index}"
  public-subnet1 = module.vpc.public_subnet1_id
  workernode_sg  = module.workernode_sg.securitygroup_id
  key_name       = aws_key_pair.deployer.key_name
}


# EC2 Key Pair - managed by Terraform
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_public_key
}

