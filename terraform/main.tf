
provider "aws" {
  region = "ap-south-1"
}


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "server_sg" {
  name        = "server-security-group"
  description = "Allow required inbound ports"

  dynamic "ingress" {
    for_each = [22, 80, 8080, 9090, 3000, 9091]

    content {
      description = "Allow port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "server-security-group"
  }
}

resource "aws_instance" "server" {
  ami                    = "ami-01a00762f46d584a1"
  instance_type          = var.instance_type
  key_name              = var.key_name
  vpc_security_group_ids = [aws_security_group.server_sg.id]

  tags = {
    Name = "DevOps-Server"
  }
}

resource "aws_ebs_volume" "my_ebs" {
  availability_zone = aws_instance.server.availability_zone
  size              = 20
  type              = "gp3"

  tags = {
    Name = "my-ebs-volume"
  }
}

# Attach EBS Volume to EC2
resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.my_ebs.id
  instance_id = aws_instance.server.id
}