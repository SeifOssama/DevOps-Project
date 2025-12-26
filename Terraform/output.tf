# === Terraform Outputs for GitHub Actions === #

# Monitoring Node Outputs
output "monitoring_node_public_ip" {
  description = "Public IP of monitoring node"
  value       = module.controlnode.control_node_public_ip
}

output "monitoring_node_private_ip" {
  description = "Private IP of monitoring node"
  value       = module.controlnode.control_node_private_ip
}

output "monitoring_node_id" {
  description = "Instance ID of monitoring node"
  value       = module.controlnode.control_node_id
}

# Webserver Outputs
output "webserver_public_ips" {
  description = "Public IPs of webservers"
  value       = module.webserver[*].webservers_public_ip
}

output "webserver_private_ips" {
  description = "Private IPs of webservers"
  value       = module.webserver[*].webservers_private_ip
}

output "webserver_ids" {
  description = "Instance IDs of webservers"
  value       = module.webserver[*].webserver_id
}

# JSON output for easy parsing in GitHub Actions
output "all_hosts_json" {
  description = "All hosts in JSON format for scripts"
  value = jsonencode({
    monitoring = {
      public_ip  = module.controlnode.control_node_public_ip
      private_ip = module.controlnode.control_node_private_ip
      id         = module.controlnode.control_node_id
    }
    webservers = [
      for idx in range(length(module.webserver)) : {
        name       = "webserver-${idx}"
        public_ip  = module.webserver[idx].webservers_public_ip
        private_ip = module.webserver[idx].webservers_private_ip
        id         = module.webserver[idx].webserver_id
      }
    ]
  })
}
