## Static Terraform Deployment of EC2 with Nginx Showing Dynamic Private IP

## Overview
This project uses Terraform to provision an AWS EC2 instance and automatically install Nginx. The deployed Nginx web page dynamically displays the private IP address of the EC2 instance using the AWS Instance Metadata Service (IMDSv2).

Prerequisites
AWS account
IAM user with EC2 permissions
AWS credentials configured (or via CI/CD)
Terraform installed
Existing EC2 key pair named Jenkins

## Providers
A provider in Terraform is a plugin that enables interaction with an API. This includes cloud providers, SaaS providers, and other APIs. The providers are specified in the Terraform configuration code. They tell Terraform which services it needs to interact with.

```hcl
provider "aws" {
  region = "us-east-1"
}
```
## Security Group Configuration

```
resource "aws_security_group" "nginx_sg" {
name_prefix = "nginx-sg-"
```

## Inbound Rules

```hcl
ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
```

* Allows HTTP traffic to access Nginx

```hcl
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

* Allows SSH access for server administration

### Outbound Rule

```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

* Allows all outbound traffic

---

## EC2 Instance Configuration

```hcl
resource "aws_instance" "nginx_instance" {
  ami           = "ami-0683ee28af6610487"
  instance_type = "t3.micro"
  key_name      = "Jenkins"
  security_groups = [aws_security_group.nginx_sg.name]
}
```

---

## User Data Script (Boot-Time Configuration)

### System Update and Nginx Installation

```bash
dnf update -y
dnf install -y nginx
systemctl enable nginx
systemctl start nginx
```

* Updates system packages
* Installs Nginx
* Ensures Nginx starts automatically on boot

---

## Fetch Private IP Using IMDSv2

```bash
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
```

* Requests a secure metadata token (IMDSv2)

```bash
PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)
```

* Retrieves the EC2 instance private IP dynamically

---

## Dynamic Web Page Creation

```bash
echo "<!DOCTYPE html>
<html>
  <body>
    <h1>CSA DevOps Exam - Instance Private IP: $PRIVATE_IP</h1>
  </body>
</html>" > /usr/share/nginx/html/index.html
```

### Explanation

* Creates an HTML page served by Nginx
* Displays the instance's private IP address
* Confirms successful deployment and metadata access

```bash
systemctl restart nginx
```

* Reloads Nginx to serve updated content

---

## Resource Tags

```hcl
tags = {
  Name = "nginx-instance"
}
```

* Adds a name tag for easier EC2 identification

---

## Terraform Outputs

```hcl
output "instance_public_ip" {
  value = aws_instance.nginx_instance.public_ip
}

output "instance_private_ip" {
  value = aws_instance.nginx_instance.private_ip
}
```

### Explanation

* Displays public IP to access the application
* Displays private IP for internal reference

---

## Terraform Commands
* Initializes the Terraform working directory.
```bash
terraform init
```

*Creates an execution plan without making any real changes.
```bash
terraform plan
```
* Applies the Terraform configuration to create or update infrastructure.
```bash
terraform apply
```
* Applies the Terraform configuration without asking for confirmation.
```bash
terraform -auto-approve
```
* Destroys all resources managed by Terraform without confirmation.
```bash
terraform -auto-destroy
```

After deployment:

* Open browser: `http://<public-ip>`
* You will see the EC2 **private IP displayed on the page**

---

