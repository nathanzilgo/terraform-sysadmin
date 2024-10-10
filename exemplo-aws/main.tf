terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

# Security Group para permitir o acesso público via porta do contêiner Docker
resource "aws_security_group" "allow_http" {
  name        = "allow_http_traffic"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = var.docker_port
    to_port     = var.docker_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Acessível por qualquer IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permitir tráfego de saída
  }
}

resource "aws_security_group" "allow_ping" {
  name        = "allow_icmp_ping"
  description = "Allow ICMP ping traffic"

  # Permitir o tráfego de ping (ICMP)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"] # Acessível por qualquer IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permitir tráfego de saída
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_traffic"
  description = "Allow SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir SSH de qualquer IP (opcional, pode ser restrito a seu IP)
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["18.237.140.160/29"] # Permitir SSH do IP do EC2 Instance Connect
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permitir tráfego de saída
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high_cpu_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "Alarm when CPU exceeds 80%"
  dimensions = {
    InstanceId = aws_instance.app_server.id
  }

  # alarm_actions = [/* ARN do SNS ou ação desejada */]
}

resource "aws_sns_topic" "alarm_topic" {
  name = "my_alarm_topic"
}

resource "aws_sns_topic_subscription" "alarm_subscription" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = "nathan.pedroza@ccc.ufcg.edu.br"
}

resource "aws_instance" "app_server" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"
  monitoring    = true
  security_groups = [
    aws_security_group.allow_http.name,
    aws_security_group.allow_ping.name,
    aws_security_group.allow_ssh.name
  ]


  tags = {
    Name = var.instance_name
  }

  user_data = <<-EOF
  #!/bin/bash
  # Atualizar pacotes e instalar o Docker e cloudwatch
  sudo apt-get update -y
  sudo apt-get install -y docker.io
  sudo apt-get install -y amazon-cloudwatch-agent

  # Iniciar e habilitar o Docker
  sudo systemctl start docker
  sudo systemctl enable docker

  # Puxar a imagem do Docker Hub
  sudo docker pull ${var.docker_image}

  # Executar o contêiner Docker com a imagem do Docker Hub na porta especificada
  sudo docker run -d -p ${var.docker_port}:${var.docker_port} ${var.docker_image}
  
  # Iniciar o CloudWatch Agent
  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
  EOF 
}