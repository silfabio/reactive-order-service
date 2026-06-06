output "cluster_arn" { value = aws_msk_cluster.main.arn }
output "bootstrap_brokers" { value = aws_msk_cluster.main.bootstrap_brokers }
output "cluster_name" { value = aws_msk_cluster.main.cluster_name }
