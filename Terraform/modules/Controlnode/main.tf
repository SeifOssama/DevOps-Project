# modules/ec2/bastion_host.tf

resource "aws_instance" "controlnode" {
  ami                         = "ami-0c398cb65a93047f2" # Replace with your preferred AMI ID (Amazon Linux 2, Ubuntu, etc.)
  instance_type               = "t2.micro"              # Use t2.micro for Free Tier
  subnet_id                   = var.public-subnet1      # Choose an appropriate public subnet
  vpc_security_group_ids      = [var.controlnode_sg]    # Attach the security group for SSH access
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.control_node_profile.name
  user_data                   = file("./modules/Controlnode/controlnode.sh")
  associate_public_ip_address = true
  tags = {
    Name = "Control Node"
    Role = "control"
  }

}


# IAM Role for Control Node
resource "aws_iam_role" "control_node_role" {
  name = "control-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy to allow EC2 describe calls 
resource "aws_iam_role_policy" "control_node_policy" {
  name = "control-node-policy"
  role = aws_iam_role.control_node_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile to attach the role to EC2
resource "aws_iam_instance_profile" "control_node_profile" {
  name = "control-node-profile"
  role = aws_iam_role.control_node_role.name
}
