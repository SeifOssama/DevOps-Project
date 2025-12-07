# modules/ec2/bastion_host.tf

resource "aws_instance" "controlnode" {
  ami           = "ami-0c398cb65a93047f2"  # Replace with your preferred AMI ID (Amazon Linux 2, Ubuntu, etc.)
  instance_type = "t2.micro"  # Use t2.micro for Free Tier
  subnet_id     = var.public-subnet1 # Choose an appropriate public subnet
  vpc_security_group_ids = [var.controlnode_sg] # Attach the security group for SSH access
  key_name = var.key_name
  user_data     = file("./modules/Controlnode/controlnode.sh")
  associate_public_ip_address = true
  tags = {
    Name = "Control Node"
  }

}


