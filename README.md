## Static Terraform Deployment of EC2 with Nginx Showing Dynamic Private IP
### Project
```
Infra-autamtion/
│
├── .gitignore
│   └── Ignores Terraform state files, logs, and sensitive data
│
├── Jenkinsfile
│   └── Jenkins CI/CD pipeline to automate Terraform init, plan, apply, and destroy
│
├── README.md
│   └── Project documentation explaining infrastructure, pipeline, and usage
│
├── instance.tf
│   └── Terraform configuration file
│       ├── AWS provider configuration
│       ├── Security Group for Nginx (HTTP & SSH)
│       ├── EC2 instance creation
│       ├── User data script to install and configure Nginx
│       └── Outputs for public and private IPs
```

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


# Jenkins Pipeline for Terraform Infrastructure Automation

##  Overview

This Jenkins pipeline automates **AWS infrastructure provisioning and destruction using Terraform**. It supports **manual approval**, **parameterized execution**, and **deployment validation**, making it suitable for real-world DevOps and production environments.

The pipeline performs the following actions:

* Clones Terraform code from GitHub
* Initializes Terraform
* Generates and reviews a Terraform plan
* Applies or destroys infrastructure based on user input
* Validates application deployment

---

##  Prerequisites

* Jenkins installed and running
* Terraform installed on Jenkins agent
* AWS IAM credentials stored in Jenkins
* GitHub repository with Terraform code

---

##  Pipeline Structure

This is a **Declarative Jenkins Pipeline**, defined using a `Jenkinsfile`.

```groovy
pipeline {
    agent any
}
```


---

## Build Parameters

```groovy
parameters {
    booleanParam(name: 'autoApprove', defaultValue: false)
    choice(name: 'action', choices: ['apply', 'destroy'])
}
```
* autoApprove: If false, manual approval is required before Terraform apply
* action: Choose whether to apply or destroy infrastructure 

These parameters control pipeline behavior at runtime:


---

##  Environment Variables (AWS Credentials)

```groovy
environment {
    AWS_ACCESS_KEY_ID     = credentials('AWS_Access_Key')
    AWS_SECRET_ACCESS_KEY = credentials('AWS_Secret_Access_Key')
    AWS_DEFAULT_REGION    = 'eu-north-1'
}
```

* AWS credentials are securely injected from Jenkins Credentials Manager
* Avoids hardcoding sensitive information
* Sets AWS region for Terraform execution

---

## Stage 1: Checkout Source Code

```groovy
stage('Checkout') {
    steps {
        git branch: 'main', url: 'https://github.com/rohansdevops/Infra-autamtion.git'
    }
}
```

* Clones the Terraform project from GitHub
* Ensures Jenkins always works with the latest code

---

## Stage 2: Terraform Initialization

```groovy
stage('Terraform init') {
    steps {
        sh 'terraform init'
    }
}
```

* Initializes Terraform working directory
* Downloads providers and configures backend

---

## Stage 3: Terraform Plan

```groovy
stage('Plan') {
    steps {
        sh 'terraform plan -out tfplan'
        sh 'terraform show -no-color tfplan > tfplan.txt'
    }
}
```

* Generates execution plan
* Saves plan for reuse and review
* Converts plan into readable text format

---

## Stage 4: Apply / Destroy Infrastructure

### Apply Flow

```groovy
if (params.action == 'apply') {
```

#### Manual Approval

```groovy
input message: "Do you want to apply the plan?"
```

* Displays Terraform plan
* Requires human confirmation (if autoApprove is false)

#### Apply Terraform Plan

```groovy
sh "terraform apply -input=false tfplan"
```

* Applies the exact plan generated earlier

---

### Destroy Flow

```groovy
else if (params.action == 'destroy') {
    sh "terraform destroy --auto-approve"
}
```

### Explanation

* Destroys all managed infrastructure
* Auto-approved to avoid unnecessary prompts

---

## Stage 5: Wait for EC2 Readiness

```groovy
stage('Configure EC2 waiting for running status') {
    steps {
        sh 'sleep 90'
    }
}
```

* Allows EC2 instance time to boot
* Ensures application is ready before validation

---

## Stage 6: Deployment Validation

```groovy
stage('Deployment Validation') {
```

### Runs only during apply

```groovy
when {
    expression { return params.action == 'apply' }
}
```

### Validation Steps

```groovy
def public_ip = sh(script: "terraform output -raw instance_public_ip")
```

* Fetches EC2 public IP from Terraform output

```groovy
def response = sh(script: "curl -s http://$public_ip")
```

* Sends HTTP request to deployed application

```groovy
if(!response.contains("CSA DevOps Exam - Instance IP:")) {
    error "Deployment validation failed"
}
```

* Verifies application content
* Fails pipeline if validation does not pass

---

##  Stage 7: Output Result

```groovy
stage('Output Result') {
    steps {
        echo "Application is deployed at http://$public_ip"
    }
}
```

* Displays deployed application URL
* Confirms successful deployment

---









