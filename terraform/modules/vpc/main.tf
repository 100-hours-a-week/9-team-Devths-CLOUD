# ============================================================================
# VPC 모듈
# ============================================================================
#
# 이 모듈은 AWS VPC 및 관련 네트워킹 리소스를 생성합니다.
#
# 구성 파일:
# - network.tf          : VPC, IGW, Subnets, Public Route Tables
# - nat.tf              : NAT Gateway/Instance, Private/Database Route Tables
# - security_groups_attachment.tf  : ALB, App, Database, EC2 Security Groups
# - variables.tf        : 입력 변수 정의
# - outputs.tf          : 출력 값 정의
#
# ============================================================================
