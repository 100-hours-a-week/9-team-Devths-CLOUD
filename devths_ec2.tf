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
resource "aws_instance" "devths_prod_app" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.devths_prod_public_01.id
  vpc_security_group_ids = [aws_security_group.devths_prod_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_prod.name

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
              wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto

              # CodeDeploy 에이전트 시작 및 활성화
              systemctl start codedeploy-agent
              systemctl enable codedeploy-agent
              EOF

  tags = {
    Name        = "devths_prod_app"
    Environment = "production"
    Project     = "devths"
  }
}

# Elastic IP (선택사항 - 고정 IP가 필요한 경우)
resource "aws_eip" "devths_prod_app_eip" {
  instance = aws_instance.devths_prod_app.id
  domain   = "vpc"

  tags = {
    Name = "devths_prod_app_eip"
  }
}
