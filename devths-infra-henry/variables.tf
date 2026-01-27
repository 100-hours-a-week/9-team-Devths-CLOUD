variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "devths"
}

variable "owner" {
  description = "리소스 소유자 이름"
  type        = string
  default     = "henry"
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "EC2 키페어 이름"
  type        = string
  default     = "devths-non-prod"
}
