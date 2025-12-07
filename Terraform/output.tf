
output "control_node_public_ip" {
    value = module.controlnode.control_node_public_ip

}



output "webservers_public_ips" {
    value = module.webserver.*.webservers_public_ip
}


output "webservers_private_ips" {
    value = module.webserver.*.webservers_public_ip
}