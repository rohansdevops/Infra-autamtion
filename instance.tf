provider "aws" {
  region = "eu-north-1" 
}

resource "aws_security_group" "nginx_sg" {
  name_prefix = "nginx-sg-"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_instance" "nginx_instance" {
  ami           = "ami-0683ee28af6610487"  
  instance_type = "t3.micro"
  key_name      = "Jenkins"          
  security_groups = [aws_security_group.nginx_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras enable nginx1
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "CSA DevOps Exam – Instance IP: $(hostname -I)" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "nginx-instance"
  }
}

output "instance_public_ip" {
  value = aws_instance.nginx_instance.public_ip
}

output "instance_private_ip" {
  value = aws_instance.nginx_instance.private_ip
}
