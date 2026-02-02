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

  root_block_device {
    volume_size           = 30     # 크기 (GB)
    volume_type           = "gp3"  # 최신 가성비 타입 gp3 권장
    iops                  = 3000   # gp3 기본 성능
    throughput            = 125    # gp3 기본 성능
    delete_on_termination = true   # 인스턴스 삭제 시 볼륨도 삭제 여부
    encrypted             = true   # 암호화 여부

    tags = {
      Name = "devths-v1-prod-root-volume"
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              export AWS_REGION="${var.aws_region}"
              ${file("${path.module}/user_data.sh")}
              ${file("${path.module}/init_db.sh")}
              ${file("${path.module}/setup_logrotate.sh")}
              EOF

  tags = {
    Name        = "devths-v1-prod"
    Environment = "production"
    Project     = "devths"
  }
}

# Elastic IP (선택사항 - 고정 IP가 필요한 경우)
resource "aws_eip" "devths_prod_app_eip" {
  instance = aws_instance.devths_prod_app.id
  domain   = "vpc"

  tags = {
    Name = "devths-v1-prod-eip"
  }
}
