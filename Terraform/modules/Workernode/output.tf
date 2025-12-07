output "webservers_public_ip" {
  value = aws_instance.webserver.*.public_ip
}

output "webservers_private_ip" {
  value = aws_instance.webserver.*.private_ip
}