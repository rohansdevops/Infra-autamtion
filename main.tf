# data "aws_ami" "amazon_linux" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["amazon"]
# }

# data "aws_vpc" "default" {
#   default = true
# }

# module "security_group" {
#   source = "./modules/security_group"

#   vpc_id = data.aws_vpc.default.id
# }

# module "ec2" {
#   source = "./modules/ec2"

#   ami_id           = data.aws_ami.amazon_linux.id
#   instance_type    = var.instance_type
#   security_group   = module.security_group.sg_id
#   key_name         = var.key_name
#   user_data_script = file("${path.module}/user-data.sh")
# }


module "security_group" {
  source = "./module/security-group"
}

module "ec2" {
  source = "./module/ec2"

  instance_type     = var.instance_type
  key_name          = var.key_name
  security_group_id = module.security_group.sg_id
  user_data_script  = "${path.root}/userdata.sh"
}
