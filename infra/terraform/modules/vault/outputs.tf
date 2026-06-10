output "security_group_id" { value = aws_security_group.vault.id }
output "asg_name" { value = aws_autoscaling_group.vault.name }
output "iam_role_arn" { value = aws_iam_role.vault.arn }
