output "security_group_id" { value = aws_security_group.vault.id }
output "asg_name" { value = aws_autoscaling_group.vault.name }
output "iam_role_arn" { value = aws_iam_role.vault.arn }

# TODO: no load balancer/DNS endpoint exists for the Vault HA cluster yet —
# this module only provisions the ASG/EC2 nodes. Until a follow-up adds one,
# production applies of module.vault_pki must supply a reachable Vault
# address via -var="vault_address=..."/TF_VAR_vault_address rather than
# this output.
output "vault_cluster_address" {
  value = ""
}
