output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the ALB target group."
  value       = aws_lb_target_group.this.arn
}

output "service_security_group_id" {
  description = "Security group ID attached to ECS tasks."
  value       = aws_security_group.service.id
}

output "alb_listener_http_arn" {
  description = "ARN of the HTTP listener. Null when HTTPS is configured."
  value       = length(aws_lb_listener.http) > 0 ? aws_lb_listener.http[0].arn : null
}

output "alb_listener_https_arn" {
  description = "ARN of the HTTPS listener. Null when certificate_arn is not set."
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
}
