output "alb_dns" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}
