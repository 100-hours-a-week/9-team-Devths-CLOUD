# 최신 Ubuntu 22.04
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 인스턴스
resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile_name

  user_data = join("\n", [
    "#!/bin/bash",
    file("${path.module}/scripts/user_data.sh"),
    file("${path.module}/scripts/init_db.sh"),
    file("${path.module}/scripts/setup_logrotate.sh"),
  ])

  tags = merge(
    var.common_tags,
    {
      Name = var.instance_name
    }
  )
}

# 공인 IP
resource "aws_eip" "this" {
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.instance_name}-eip"
    }
  )
}
