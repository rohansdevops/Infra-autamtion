# variable "aws_region" {
#   description = "AWS region"
#   type        = string
#   default     = "eu-north-1"
# }

# variable "instance_type" {
#   description = "EC2 instance type"
#   type        = string
#   default     = "t3.micro"
# }

# variable "key_name" {
#   description = "Optional SSH key name"
#   type        = string
#   default     = null
# }


variable "aws_region" {
  default = "eu-north-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  default = null
}
