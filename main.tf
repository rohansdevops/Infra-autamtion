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
