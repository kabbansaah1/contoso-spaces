/* output "load_balancer_dns_name" {
  description = "The DNS name of the AWS ALB"
  value       = aws_lb.my_alb.dns_name
} */
/* 
output "load_balancer_arn" {
  description = "The ARN of the AWS ALB"
  value       = aws_lb.my_alb.arn
}

output "route53_zone_id" {
  description = "The Route 53 hosted zone ID"
  value       = aws_route53_zone.afroredding.zone_id
}

output "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate"
  value       = aws_acm_certificate.afroredding.arn
}

output "security_group_id" {
  description = "The ID of the security group associated with the ALB"
  value       = aws_security_group.alb_sg.id
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.my_vpc.id
}


 */