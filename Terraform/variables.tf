# === ROOT Variables === #

# Variable for VPC CIDR block
variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}


# Public Subnet CIDR blocks
variable "public-subnet1_cidr" {
  description = "CIDR block for Public Subnet 1"
  default     = "10.0.1.0/24"
}

# Availability Zones
variable "availability_zone_a" {
  description = "Availability Zone for Public Subnet A"
  default     = "us-east-1a"
}
