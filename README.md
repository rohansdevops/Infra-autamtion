### Automated AWS EC2 infrastructure provisioning using Terraform modules and Jenkins CI/CD pipeline.

## Project Structure
```bash
terraform-jenkins-infra-automation/
│
├── module/
│   ├── ec2/
│   │   ├── main.tf         EC2 instance resource 
│   │   ├── variable.tf     Input variables for EC2 module
│   │   └── output.tf       EC2 outputs (public/private IP)
│   │
│   └── security-group/
│       ├── main.tf        Security Group rules (HTTP & SSH)
│       ├── variable.tf    Input variables for Security Group
│       └── output.tf      Security Group ID output
│
├── provider.tf             AWS provider configuration
│
├── main.tf                 Root module calling EC2 & SG modules
│
├── variable.tf             Global variables (region, instance type, AMI, key)
│
├── output.tf               Final outputs exposed after deployment
│
├── userdata.sh             Bash script to install & configure Nginx
│
├── Jenkinsfile              Jenkins pipeline to automate Terraform workflow
│
├── .gitignore               Ignore Terraform state files and sensitive data
│
└── README.md                Complete project documentation
```

## Providers
A provider in Terraform is a plugin that enables interaction with an API. This includes cloud providers, SaaS providers, and other APIs. The providers are specified in the Terraform configuration code. They tell Terraform which services it needs to interact with.
The required_providers block in Terraform is used to declare and specify the required provider configurations for your Terraform module or configuration. It allows you to specify the provider name, source, and version constraints.

```bash
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```
## Variables
Input and output variables in Terraform are essential for parameterizing and sharing values within your Terraform configurations and modules. They allow you to make your configurations more dynamic, reusable, and flexible.

## Input Variables`
Input variables are used to parameterize your Terraform configurations. They allow you to pass values into your modules or configurations from the outside. Input variables can be defined within a module or at the root level of your configuration. Here's how you define an input variable:
```bash
variable "instance_type" {}
variable "key_name" {
  default = null
}

variable "security_group_id" {}

variable "user_data_script" {
  description = "User data script path"
}
```
In this example:

* variable is used to declare an input variable named example_var.
* description provides a human-readable description of the variable.
* type specifies the data type of the variable (e.g., string, number, list, map, etc.).
* default provides a default value for the variable, which is optional.

## Output Variables
Output variables allow you to expose values from your module or configuration, making them available for use in other parts of your Terraform setup. Here's how you define an output variable.

```bash
output "instance_public_ip" {
  value = module.ec2.public_ip
}

output "ec2_public_dns" {
  value = module.ec2.public_dns
}
```

* output is used to declare an output variable named example_output.
* description provides a description of the output variable.
* value specifies the value that you want to expose as an output variable. This value can be a resource attribute, a computed value, or any other expression.

## Modules
Terraform modules help improve the organization, reusability, and maintainability of infrastructure as code by breaking configurations into smaller, reusable components such as VPC, EC2, or databases. They reduce code duplication, make collaboration easier for teams, and allow updates or changes to be managed centrally through versioning. Modules also abstract complex configurations, simplify testing, and enforce security best practices, making infrastructure more scalable, consistent, and production-ready.

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

## 🔐 Environment Variables (AWS Credentials)

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
