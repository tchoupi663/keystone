
# ──────────────────────────────────────────────
# ALB
# ──────────────────────────────────────────────

output "alb_id" {
  description = "The ID of the ALB"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "The DNS name of the ALB (use for DNS CNAME / Route 53 alias)"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ALB (for Route 53 alias records)"
  value       = aws_lb.this.zone_id
}

# ──────────────────────────────────────────────
# Security Group
# ──────────────────────────────────────────────

output "alb_security_group_id" {
  description = "ID of the security group attached to the ALB (reference in ECS task SG ingress rules)"
  value       = aws_security_group.alb.id
}

# ──────────────────────────────────────────────
# Target Group
# ──────────────────────────────────────────────

output "target_group_arn" {
  description = "ARN of the default target group (attach ECS services here)"
  value       = aws_lb_target_group.default.arn
}

output "target_group_name" {
  description = "Name of the default target group"
  value       = aws_lb_target_group.default.name
}

# ──────────────────────────────────────────────
# Listeners
# ──────────────────────────────────────────────

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (null when HTTPS is disabled)"
  value       = var.enable_https ? aws_lb_listener.https[0].arn : null
}
