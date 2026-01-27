# VPC 서브넷 작성
resource "aws_vpc" "devths_prod" {
 cidr_block = "10.0.0.0/16"
 
 tags = {
   Name = "devhts_prod"
 }
}

# 퍼블릭 서브넷 1
resource "aws_subnet" "devths_prod_public_01" {
 vpc_id = aws_vpc.devths_prod.id
 cidr_block = "10.0.0.0/24"
 
 availability_zone = "ap_northeast-2a"

 tags = {
  Name = "devths_prod_public_01"
 }

}

# 퍼블릭 서브넷 2
resource "aws_subnet" "devhts_prod_public_02" {
 vpc_id = aws_vpc.devths_prod.id
 cidr_block = "10.0.1.0/24"
 
 availability_zone = "ap_northeast-2a"

 tags = {
  Name = "devhts_prod_public_02"
 }
}
