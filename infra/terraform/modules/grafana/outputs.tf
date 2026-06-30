output "dashboard_uid" {
  description = "UID of the provisioned Grafana dashboard"
  value       = grafana_dashboard.order_service.uid
}

output "folder_uid" {
  description = "UID of the Order Service Grafana folder"
  value       = grafana_folder.order_service.uid
}

output "datasource_uid" {
  description = "UID of the Prometheus Grafana datasource"
  value       = grafana_data_source.prometheus.uid
}
