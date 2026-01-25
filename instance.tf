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
dnf update -y
dnf install -y nginx
systemctl enable nginx
systemctl start nginx


TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")


PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)


echo "<!DOCTYPE html>
<html>
  <body>
    <h1>CSA DevOps Exam - Instance Private IP: $PRIVATE_IP</h1>
  </body>
</html>" > /usr/share/nginx/html/index.html

systemctl restart nginx
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
