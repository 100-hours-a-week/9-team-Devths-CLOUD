# 1. VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16" # IP 대역폭 설정 (약 65,000개 IP 사용 가능)
  enable_dns_hostnames = true          # 도메인 이름 사용 허용
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc-tf-test" # AWS 콘솔에서 보일 이름
  }
}

# 2. Public Subnet 생성 (외부 통신 가능한 구역)
# 가용영역 A (예: ap-northeast-2a)
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"     # 10.0.1.x 대역 사용
  availability_zone = "${var.region}a" # 서울 리전 A존

  # 이 서브넷에 생기는 EC2는 자동으로 공인 IP를 가짐
  map_public_ip_on_launch = true 

  tags = {
    Name = "${var.project_name}-public-subnet-a"
  }
}

# 가용영역 C (예: ap-northeast-2c) - 고가용성을 위해 하나 더 만듬
resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"     # 10.0.2.x 대역 사용
  availability_zone = "${var.region}c" # 서울 리전 C존
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-c"
  }
}

# 3. Internet Gateway (IGW) 생성 (인터넷으로 나가는 문)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-tf-test"
  }
}

# 4. Route Table 생성 (표지판 역할)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  # 모든 트래픽(0.0.0.0/0)은 인터넷 게이트웨이(IGW)로 보내라
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-tf-test"
  }
}

# 5. Route Table 연결 (서브넷과 표지판 연결)
resource "aws_route_table_association" "public_a_association" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_c_association" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public_rt.id
}