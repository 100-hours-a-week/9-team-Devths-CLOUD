# Current AWS Region
data "aws_region" "current" {}

# Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_nat" {
  count       = local.actual_nat_type == "instance" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}