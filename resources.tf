data "aws_vpc" "default" { 
    default                 = true
    # Checa qual VPC está definida como default na conta
} 

resource "aws_autoscaling_group" "asg_brandon" {
    launch_configuration    = aws_launch_configuration.asg_lc_brandon.name
    vpc_zone_identifier     = ["subnet-32790a1a","subnet-f77121b1"]
    
    target_group_arns       = [aws_lb_target_group.asg_alb_tg_brandon.arn] 
    health_check_type       = "ELB"

    min_size                = 2
    max_size                = 4

    tag {
        key                 = "Name"
        value               = "terraform-asg"
        propagate_at_launch = true #propaga a tag para todas as EC2 do ASG
    }

    lifecycle {
        create_before_destroy = true

    }
    # Cria o autoscalling group utilizando o launch configuration, target group e propaga as tags.
    # Determina o tamanho do ASG
    # Determina em quais VPCs as máquinas serão criadas
}

resource "aws_launch_configuration" "asg_lc_brandon" {
    image_id                = var.AMI
    instance_type           = "t2.micro"
    security_groups         = [aws_security_group.asg_sg_brandon.id]

    # Parâmetros das EC2 que serão criadas no ASG
}

resource "aws_lb" "asg_lb_brandon" {
    name                    = "terraform-lb-brandon"
    load_balancer_type      = "application"
    subnets                 = ["subnet-32790a1a", "subnet-f77121b1"]
    security_groups         = [aws_security_group.asg_alb_sg_brandon.id]

    # Cria o loadbalancer e define o tipo
    # Determina em quais redes o loadbalancer irá atuar e define o security group
}

resource "aws_lb_listener" "http_listener" {
    load_balancer_arn       = aws_lb.asg_lb_brandon.arn
    port                    = var.PORT_80
    protocol                = "HTTP"

    default_action {
      type = "fixed-response"

      fixed_response {
        content_type        = "text/plain"
        message_body        = "404: page not found"
        status_code         = 404
      }
    }

    # Cria um listener para o loadbalancer e define seus parâmetros e resposta
}

resource "aws_lb_listener_rule" "asg_listener_rule_brandon" {
    listener_arn            = aws_lb_listener.http_listener.arn
    priority                = 100

    condition {
      path_pattern {
        values              = ["*"]
      }
    }

    action {
      type = "forward"
      target_group_arn      = aws_lb_target_group.asg_alb_tg_brandon.arn
    }

    # Cria uma regra para o listener e passa a requisição para o Target Group
}

resource "aws_lb_target_group" "asg_alb_tg_brandon" {
    name                    = "terraform-alb-health-check"
    port                    = var.PORT_8080
    protocol                = "HTTP"
    vpc_id                  = data.aws_vpc.default.id

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }

    # Cria o health check utilizando o target group para definir quais instâncias reciclar
}

resource "aws_security_group" "asg_alb_sg_brandon" {
    name                    = "terraform-alb-listener-sg"

    ingress{
        from_port           = var.PORT_80
        to_port             = var.PORT_80
        protocol            = "tcp"
        cidr_blocks         = ["0.0.0.0/0"]
    }

    egress {
        from_port           = 0
        to_port             = 0
        protocol            = "tcp"
        cidr_blocks         = ["0.0.0.0/0"]
    }

    # Security group a ser utilizado pelo listener
}

resource "aws_security_group" "asg_sg_brandon" {
    name                    = "asg_sg_brandon"

    ingress {
        from_port           = var.PORT_8080
        to_port             = var.PORT_8080
        protocol            = "TCP" 
        cidr_blocks         = ["0.0.0.0/0"]
    }

    egress{
        from_port           = 0
        to_port             = 0
        protocol            = "-1"
        cidr_blocks         = ["0.0.0.0/0"]
    }

    # Security group a ser utilizado pelas EC2 do ASG
}