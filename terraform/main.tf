terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "vle5_key" {
  key_name   = "vle5-key"
  public_key = file(pathexpand("~/.ssh/vle5-key.pub"))
}

resource "aws_security_group" "vle5_sg" {
  name        = "vle5-devops-sg"
  description = "VLE-5 SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "VLE5-Security-Group"
  }
}

resource "aws_instance" "devops_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.vle5_key.key_name
  vpc_security_group_ids = [aws_security_group.vle5_sg.id]

  tags = {
    Name = "VLE5-DevOps-Server"
  }
}

output "public_ip" {
  value = aws_instance.devops_server.public_ip
}

output "instance_id" {
  value = aws_instance.devops_server.id
}