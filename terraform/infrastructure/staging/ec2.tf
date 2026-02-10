# EC2 모듈
module "ec2" {
  source = "../../modules/ec2"

  instance_name             = "${var.project_name}-v2-${var.environment}"
  instance_type             = var.instance_type
  key_name                  = var.key_name
  subnet_id                 = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  security_group_id         = data.terraform_remote_state.vpc.outputs.ec2_security_group_id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  aws_region                = var.aws_region
  enable_eip                = var.enable_eip
  environment               = var.environment
  domain_name               = "devths.com"
  discord_webhook_url       = var.discord_webhook_url

  common_tags = var.common_tags

  depends_on = [module.iam]
}
