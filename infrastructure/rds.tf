# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "job-portal-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = { Name = "job-portal-db-subnet-group", Project = "job-portal" }
}

# RDS MySQL Instance
resource "aws_db_instance" "main" {
  identifier              = "job-portal-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  storage_encrypted       = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  skip_final_snapshot     = true
  multi_az                = false
  publicly_accessible     = false
  deletion_protection     = false

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  parameter_group_name = "default.mysql8.0"

  tags = { Name = "job-portal-db", Project = "job-portal" }
}
