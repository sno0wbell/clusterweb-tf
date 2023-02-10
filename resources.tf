data "aws_vpc" "default" {
    default                     = true
    #Captura qual VPC é a padrão na minha conta
}

data "aws_subnets" "default" {
    filter{
        name                    = "vpc-id"
        values                  = [data.aws_vpc.default.id]
    }
}

resource "aws_launch_configuration" "web8080" {
    image_id                    = var.AMI
    instance_type               = "t2.micro"
    security_groups             = [aws_security_group.teste8080.id]

    user_data                   = <<-EOF
                                #!/bin/bash
                                echo "Porta acessível." > index.html
                                nohup busybox httpd -f -p ${var.port8080} &
                                EOF

    #Configuração das EC2 que serão lançadas no target group
}

resource "aws_autoscaling_group" "web-asg" {
    launch_configuration        = aws_launch_configuration.web8080.name
    vpc_zone_identifier         = ["ID DAS SUAS SUBNETS"]

    target_group_arns           = [aws_lb_target_group.web-tg.arn]
    health_check_type           = "ELB"

    min_size = 2
    max_size = 4

    tag {
        key                     = "Name"
        value                   = "brandon-web-asg"
        propagate_at_launch     = true
    }

    lifecycle {
        create_before_destroy   = true
    }

    #Configuração do ASG
}

resource "aws_lb" "web-alb" {
    name                        = "ALB-terraform"
    load_balancer_type          = "application"
    subnets                     = ["ID-DAS-SUAS-SUBNETS"]
    security_groups             = [aws_security_group.web-sg-alb.id]

    #Configuração do Load Balancer
}

resource "aws_lb_listener" "http" {
    load_balancer_arn           = aws_lb.web-alb.arn
    port                        = 80
    protocol                    = "HTTP"

    default_action {
        type                    = "fixed-response"

        fixed_response {
            content_type        = "text/plain"
            message_body        = "404: page not found"
            status_code         = 404
        }
    }

    #Listener para o Load Balancer criado
}

resource "aws_lb_listener_rule" "http-rule" {
    listener_arn                = aws_lb_listener.http.arn
    priority                    = 100

    condition {
      path_pattern {
        values                  = ["*"]
      }
    }
  
    action {
      type                      = "forward"
      target_group_arn          = aws_lb_target_group.web-tg.arn
    }

    #Regra para o listener com priordade 100 de execução
}

resource "aws_lb_target_group" "web-tg" {
    name                        = "tg-terraform"
    port                        = var.port8080
    protocol                    = "HTTP"
    vpc_id                      = data.aws_vpc.default.id

    health_check {
        path                    = "/"
        protocol                = "HTTP"
        matcher                 = "200"
        interval                = 15
        timeout                 = 3
        healthy_threshold       = 2
        unhealthy_threshold     = 2
    }

    #Target group para o health check que tornará possível o self-healing do cluster
}

resource "aws_security_group" "web-sg-alb" {
    name                        = "ALB-SG-terraform"

    ingress {
        from_port               = 80
        to_port                 = 80
        protocol                = "tcp"
        cidr_blocks             = ["0.0.0.0/0"]
    }

    egress {
        from_port               = 0
        to_port                 = 0
        protocol                = "-1"
        cidr_blocks             = ["0.0.0.0/0"]
    }

    #Security group que permite requisições http através do Load Balancer
}

resource "aws_security_group" "teste8080" {
    name                        = "Testando 8080"

    ingress {
        from_port               = var.port8080
        to_port                 = var.port8080
        protocol                = "tcp"
        cidr_blocks             = ["0.0.0.0/0"]
    }

    #Security group que as EC2 utilizarão, permitindo conexões na porta 8080
}