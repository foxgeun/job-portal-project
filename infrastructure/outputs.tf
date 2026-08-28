output "alb_dns_name" {
  description = "Application Load Balancer의 DNS 주소"
  value       = aws_lb.main.dns_name
}

output "ec2_public_ip" {
  description = "EC2 서버 공인 IP (Elastic IP)"
  value       = aws_eip.app_server_eip.public_ip
}

output "rds_endpoint" {
  description = "RDS MySQL 엔드포인트"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS MySQL 포트"
  value       = aws_db_instance.main.port
}

output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}

output "app_url" {
  description = "애플리케이션 접근 URL"
  value       = "http://${aws_lb.main.dns_name}"
}
