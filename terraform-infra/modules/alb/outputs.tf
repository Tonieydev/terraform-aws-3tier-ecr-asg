output "target_group_arn" {
  value      = aws_lb_target_group.main.arn
  depends_on = [aws_lb_listener.http, aws_lb_listener.https]
}

output "target_group_arn_suffix" { value = aws_lb_target_group.main.arn_suffix }
output "lb_arn_suffix"           { value = aws_lb.main.arn_suffix }
output "dns_name"                { value = aws_lb.main.dns_name }
output "zone_id"                 { value = aws_lb.main.zone_id }

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}