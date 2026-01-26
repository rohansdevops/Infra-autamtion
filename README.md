## Static Terraform Deployment of EC2 with Nginx Showing Dynamic Private IP

## Overview
This project uses Terraform to provision an AWS EC2 instance and automatically install Nginx. The deployed Nginx web page dynamically displays the private IP address of the EC2 instance using the AWS Instance Metadata Service (IMDSv2).

Prerequisites
AWS account
IAM user with EC2 permissions
AWS credentials configured (or via CI/CD)
Terraform installed
Existing EC2 key pair named Jenkins

Providers.
A provider in Terraform is a plugin that enables interaction with an API. This includes cloud providers, SaaS providers, and other APIs. The providers are specified in the Terraform configuration code. They tell Terraform which services it needs to interact with.

```
provider "aws" {
  region = "us-east-1"
}
```




