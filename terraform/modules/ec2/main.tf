# 최신 Ubuntu 22.04 LTS AMI 가져오기
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

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # 시스템 업데이트
              apt-get update
              apt-get upgrade -y

              # 필수 패키지 설치
              apt-get install -y ruby-full wget

              # CodeDeploy 에이전트 설치
              cd /home/ubuntu
              wget https://aws-codedeploy-${var.aws_region}.s3.${var.aws_region}.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto

              # CodeDeploy 에이전트 시작 및 활성화
              systemctl start codedeploy-agent
              systemctl enable codedeploy-agent
              EOF

  tags = merge(
    var.common_tags,
    {
      Name = var.instance_name
    }
  )
}

# Elastic IP
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
