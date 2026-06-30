variable "prometheus_url" {
  description = "Prometheus URL reachable from inside Grafana's Docker network"
  type        = string
  default     = "http://prometheus:9090"
}

variable "alert_email" {
  description = "Email address for Grafana alert notifications"
  type        = string
}
