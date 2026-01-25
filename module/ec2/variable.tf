# variable "ami_id" {
#   type = string
# }

# variable "instance_type" {
#   type = string
# }

# variable "security_group" {
#   type = string
# }

# variable "key_name" {
#   type    = string
#   default = null
# }

# variable "user_data_script" {
#   type = string
# }

# variable "instance_type" {}
# variable "key_name" {}
# variable "security_group_id" {}

variable "instance_type" {}
variable "key_name" {
  default = null
}

variable "security_group_id" {}

variable "user_data_script" {
  description = "User data script path"
}
