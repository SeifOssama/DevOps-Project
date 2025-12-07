variable "public-subnet1" {
  description = "ID of Public Subnet 1"
  
}

variable "workernode_sg" {
  type = string
  
}


variable "name" {
  type        = string
  description = "Name of the EC2"
}

variable "key_name" {
  type        = string
  description = "Name of the SSH key pair for EC2"
}
