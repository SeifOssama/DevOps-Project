
output "control_node_public_ip" {
  value = aws_instance.controlnode.public_ip
}

output "control_node_private_ip" {
  value = aws_instance.controlnode.private_ip
}

output "control_node_id" {
  value = aws_instance.controlnode.id
}
