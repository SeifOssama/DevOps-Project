variable "public-subnet1" {
  description = "ID of Public Subnet 1"
  
}

variable "controlnode_sg" {
  type = string
  
}


variable "key_name" {
  type        = string
  description = "Name of the SSH key pair for EC2"
}
