# 최신 Amazon Linux 2 AMI 가져오기
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 인스턴스
resource "aws_instance" "devths_prod_app" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.devths_prod_public_01.id
  vpc_security_group_ids = [aws_security_group.devths_prod_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.devths_prod_ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y ruby wget

              # CodeDeploy 에이전트 설치
              cd /home/ec2-user
              wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto

              # CodeDeploy 에이전트 시작
              service codedeploy-agent start

              # 시스템 부팅 시 자동 시작 설정
              chkconfig codedeploy-agent on
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
