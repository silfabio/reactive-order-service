terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

resource "grafana_data_source" "prometheus" {
  type = "prometheus"
  name = "Prometheus"
  url  = var.prometheus_url
  json_data_encoded = jsonencode({
    httpMethod     = "POST"
    prometheusType = "Prometheus"
  })
}

resource "grafana_folder" "order_service" {
  title = "Order Service"
}

resource "grafana_dashboard" "order_service" {
  folder = grafana_folder.order_service.uid
  config_json = templatefile("${path.module}/../../../grafana/dashboards/order-service.json.tpl", {
    datasource_uid = grafana_data_source.prometheus.uid
  })
}

resource "grafana_contact_point" "email" {
  name = "Email Alerts"
  email {
    addresses               = [var.alert_email]
    disable_resolve_message = false
    single_email            = false
  }
}

resource "grafana_notification_policy" "default" {
  group_by        = ["grafana_folder", "alertname"]
  contact_point   = grafana_contact_point.email.name
  group_wait      = "10s"
  group_interval  = "2m"
  repeat_interval = "1h"
}

resource "grafana_rule_group" "order_service" {
  name             = "Order Service Alerts"
  folder_uid       = grafana_folder.order_service.uid
  interval_seconds = 30

  rule {
    name           = "High Order Creation Latency"
    condition      = "C"
    for            = "5m"
    no_data_state  = "NoData"
    exec_err_state = "Error"
    annotations = {
      summary     = "Order creation p95 latency exceeds 2 seconds"
      description = "The p95 latency for order creation has been above 2s for 5 minutes. Check for slow database queries or downstream dependencies."
    }
    labels = { severity = "warning" }

    data {
      ref_id         = "A"
      datasource_uid = grafana_data_source.prometheus.uid
      relative_time_range {
        from = 300
        to   = 0
      }
      model = jsonencode({
        datasource    = { type = "prometheus", uid = grafana_data_source.prometheus.uid }
        expr          = "histogram_quantile(0.95, sum(rate(orders_creation_duration_seconds_bucket{application=\"Reactive Order Service\"}[5m])) by (le))"
        instant       = true
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "A"
      })
    }
    data {
      ref_id         = "C"
      datasource_uid = "-100"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        conditions = [{
          evaluator = { params = [2], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["A"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
        datasource    = { type = "__expr__", uid = "-100" }
        expression    = ""
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "C"
        type          = "classic_conditions"
      })
    }
  }

  rule {
    name           = "High HTTP Error Rate"
    condition      = "C"
    for            = "5m"
    no_data_state  = "NoData"
    exec_err_state = "Error"
    annotations = {
      summary     = "HTTP 5xx error rate exceeds 5%"
      description = "More than 5% of HTTP requests are returning server errors. Investigate application logs immediately."
    }
    labels = { severity = "critical" }

    data {
      ref_id         = "A"
      datasource_uid = grafana_data_source.prometheus.uid
      relative_time_range {
        from = 300
        to   = 0
      }
      model = jsonencode({
        datasource    = { type = "prometheus", uid = grafana_data_source.prometheus.uid }
        expr          = "sum(rate(http_server_requests_seconds_count{application=\"Reactive Order Service\",outcome=\"SERVER_ERROR\"}[5m])) / sum(rate(http_server_requests_seconds_count{application=\"Reactive Order Service\"}[5m])) * 100"
        instant       = true
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "A"
      })
    }
    data {
      ref_id         = "C"
      datasource_uid = "-100"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        conditions = [{
          evaluator = { params = [5], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["A"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
        datasource    = { type = "__expr__", uid = "-100" }
        expression    = ""
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "C"
        type          = "classic_conditions"
      })
    }
  }

  rule {
    name           = "App Instance Down"
    condition      = "C"
    for            = "0s"
    no_data_state  = "Alerting"
    exec_err_state = "Alerting"
    annotations = {
      summary     = "Reactive Order Service is unreachable"
      description = "Prometheus cannot scrape the Order Service. The instance may be down or the actuator endpoint is unhealthy."
    }
    labels = { severity = "critical" }

    notification_settings {
      contact_point = grafana_contact_point.email.name
    }

    data {
      ref_id         = "A"
      datasource_uid = grafana_data_source.prometheus.uid
      relative_time_range {
        from = 120
        to   = 0
      }
      model = jsonencode({
        datasource    = { type = "prometheus", uid = grafana_data_source.prometheus.uid }
        expr          = "up{job=\"reactive-order-service\"}"
        instant       = true
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "A"
      })
    }
    data {
      ref_id         = "C"
      datasource_uid = "-100"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        conditions = [{
          evaluator = { params = [1], type = "lt" }
          operator  = { type = "and" }
          query     = { params = ["A"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
        datasource    = { type = "__expr__", uid = "-100" }
        expression    = ""
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "C"
        type          = "classic_conditions"
      })
    }
  }

  rule {
    name           = "High JVM Heap Usage"
    condition      = "C"
    for            = "10m"
    no_data_state  = "NoData"
    exec_err_state = "Error"
    annotations = {
      summary     = "JVM heap usage above 90%"
      description = "The JVM heap has been above 90% for 10 minutes. The application may OOM soon. Check for memory leaks."
    }
    labels = { severity = "warning" }

    data {
      ref_id         = "A"
      datasource_uid = grafana_data_source.prometheus.uid
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        datasource    = { type = "prometheus", uid = grafana_data_source.prometheus.uid }
        expr          = "sum(jvm_memory_used_bytes{application=\"Reactive Order Service\",area=\"heap\"}) / sum(jvm_memory_max_bytes{application=\"Reactive Order Service\",area=\"heap\"}) * 100"
        instant       = true
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "A"
      })
    }
    data {
      ref_id         = "C"
      datasource_uid = "-100"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        conditions = [{
          evaluator = { params = [90], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["A"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
        datasource    = { type = "__expr__", uid = "-100" }
        expression    = ""
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "C"
        type          = "classic_conditions"
      })
    }
  }

  rule {
    name           = "Excessive Resilience4j Retries"
    condition      = "C"
    for            = "5m"
    no_data_state  = "NoData"
    exec_err_state = "Error"
    annotations = {
      summary     = "High Resilience4j retry failure rate"
      description = "The retry failure rate has exceeded 0.1/sec for 5 minutes, indicating persistent downstream issues."
    }
    labels = { severity = "warning" }

    data {
      ref_id         = "A"
      datasource_uid = grafana_data_source.prometheus.uid
      relative_time_range {
        from = 300
        to   = 0
      }
      model = jsonencode({
        datasource    = { type = "prometheus", uid = grafana_data_source.prometheus.uid }
        expr          = "sum(rate(resilience4j_retry_calls_total{application=\"Reactive Order Service\",kind=\"failed_with_retry\"}[5m]))"
        instant       = true
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "A"
      })
    }
    data {
      ref_id         = "C"
      datasource_uid = "-100"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        conditions = [{
          evaluator = { params = [0.1], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["A"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
        datasource    = { type = "__expr__", uid = "-100" }
        expression    = ""
        intervalMs    = 1000
        maxDataPoints = 43200
        refId         = "C"
        type          = "classic_conditions"
      })
    }
  }
}
