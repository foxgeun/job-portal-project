# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.key_name

  user_data = <<-SCRIPT
    #!/bin/bash
    dnf update -y
    dnf install -y docker awscli
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    mkdir -p /home/ec2-user/scripts /home/ec2-user/logs
    chown -R ec2-user:ec2-user /home/ec2-user/scripts /home/ec2-user/logs
    chmod 755 /home/ec2-user/scripts /home/ec2-user/logs
  SCRIPT

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name    = "job-portal-app"
    Project = "job-portal"
    Role    = "application-server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP
resource "aws_eip" "app_server_eip" {
  instance   = aws_instance.app_server.id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = { Name = "job-portal-app-eip", Project = "job-portal" }
}

# ALB Target Group Attachment
resource "aws_lb_target_group_attachment" "app_server" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server.id
  port             = 8080
}
