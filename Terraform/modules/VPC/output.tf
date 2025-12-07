# ---------------------------------------------------------------------
# Outputs - Displaying Important Information after Terraform Apply
# ---------------------------------------------------------------------
# modules/vpc/outputs.tf

output "vpc_id" {
  value = aws_vpc.YAKOUT-VPC.id
}

output "public_subnet1_id" {
  value = aws_subnet.public-subnet1.id
}

