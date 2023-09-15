terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "kabbansaah1-demo-deploy"
    key     = "contoso-project/terraform.tfstate"
    profile = "itadmin"
    region  = "us-east-1"
  }

}

provider "aws" {
  region = var.region # Change to your desired region
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "${var.region}a" # Adjust AZs as needed
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.afroredding]

}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "${var.region}b" # Adjust AZs as needed
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.afroredding]
}

resource "aws_security_group" "http" {
  description = "Security group for http"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "https" {
  description = "Security group for https"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "egress-all" {
  description = "Security group for egress-all"
  vpc_id      = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress-api" {
  name        = "ingress-api"
  description = "Allow ingress to API"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_internet_gateway" "afroredding" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_lb_target_group" "target-group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.my_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path    = "/"
  }
}

resource "aws_lb" "my-alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.http.id, aws_security_group.https.id, aws_security_group.egress-all.id]

  depends_on = [aws_internet_gateway.afroredding]
}

resource "aws_acm_certificate" "afroredding" {
  domain_name               = "afroredding.com"       # Replace with your domain name
  subject_alternative_names = ["www.afroredding.com"] # Add more if needed
  validation_method         = "DNS"
}

resource "aws_lb_listener" "listener-https" {
  load_balancer_arn = aws_lb.my-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.afroredding.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}
resource "aws_lb_listener" "listener-http" {
  load_balancer_arn = aws_lb.my-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

/* resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-sg-"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_acm_certificate" "afroredding" {
  domain_name       = "afroredding.com" # Replace with your domain name
  subject_alternative_names = ["www.afroredding.com"] # Add more if needed
  validation_method = "DNS"
}

resource "aws_route53_zone" "afroredding" {
  name = "afroredding.com" # Replace with your domain name
}

resource "aws_route53_record" "afroredding" {
  name    = "afroredding.com" # Replace with your domain name
  type    = "A"
  zone_id = aws_route53_zone.afroredding.zone_id
  alias {
    name                   = aws_lb.my_alb.dns_name
    zone_id                = aws_lb.my_alb.zone_id
    evaluate_target_health = false
  }
}

 */