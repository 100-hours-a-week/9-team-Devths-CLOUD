# -----------------------------------------------------------
# 1. 보안 그룹 (Security Group) - 방화벽
# -----------------------------------------------------------
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg-${var.owner}"
  description = "Allow HTTP/HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  # 인바운드: HTTP (80) - 누구나 접속 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 인바운드: HTTPS (443) - 누구나 접속 허용
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드: 모든 트래픽 허용 (패키지 설치 등을 위해 필수)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg-${var.owner}"
  }
}

# -----------------------------------------------------------
# 2. AMI 및 EC2 생성
# -----------------------------------------------------------
# Ubuntu 24.04 최신 이미지 자동 검색
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name = var.key_name

  subnet_id                   = aws_subnet.public_a.id       # main.tf의 A존 서브넷에 배치
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name # SSM 권한 장착 (iam.tf 참조)
  associate_public_ip_address = true                         # 공인 IP 부여

  # 인스턴스 시작 시 자동 실행할 스크립트 지정
  user_data = file("user_data.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # 편의를 위해 태그 지정
  tags = {
    Name = "${var.project_name}-app-server"
  }
}

# -----------------------------------------------------------
# 3. 접속 IP 출력 (편의용)
# -----------------------------------------------------------
output "server_public_ip" {
  value = aws_instance.app_server.public_ip
  description = "접속할 EC2의 공인 IP"
}