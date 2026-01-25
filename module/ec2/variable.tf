variable "instance_type" {}
variable "key_name" {
  default = null
}

variable "security_group_id" {}

variable "user_data_script" {
  description = "User data script path"
}
