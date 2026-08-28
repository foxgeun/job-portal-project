variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID (ap-northeast-2 기준)"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 SSH 키 페어 이름"
  type        = string
}

variable "db_instance_class" {
  description = "RDS 인스턴스 타입"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "jobportal"
}

variable "db_username" {
  description = "데이터베이스 관리자 계정"
  type        = string
}

variable "db_password" {
  description = "데이터베이스 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "saramin_api_key" {
  description = "사람인 오픈 API 키"
  type        = string
  sensitive   = true
}
