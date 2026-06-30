{
  "schemaVersion": 39,
  "uid": "reactive-order-service",
  "title": "Reactive Order Service",
  "tags": ["spring-boot", "kafka", "reactive"],
  "refresh": "30s",
  "time": {"from": "now-1h", "to": "now"},
  "timezone": "browser",
  "panels": [
    {
      "type": "stat",
      "id": 1,
      "title": "Request Rate",
      "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "sum(rate(http_server_requests_seconds_count{application=\"Reactive Order Service\"}[1m]))",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "reqps",
          "color": {"mode": "fixed", "fixedColor": "blue"}
        }
      }
    },
    {
      "type": "stat",
      "id": 2,
      "title": "HTTP Error Rate",
      "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "sum(rate(http_server_requests_seconds_count{application=\"Reactive Order Service\",outcome=\"SERVER_ERROR\"}[5m])) / sum(rate(http_server_requests_seconds_count{application=\"Reactive Order Service\"}[5m])) * 100",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "noValue": "0",
          "color": {"mode": "thresholds"},
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "yellow", "value": 1},
              {"color": "red", "value": 5}
            ]
          }
        }
      }
    },
    {
      "type": "stat",
      "id": 3,
      "title": "Order p95 Latency",
      "gridPos": {"h": 4, "w": 6, "x": 12, "y": 0},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "histogram_quantile(0.95, sum(rate(orders_creation_duration_seconds_bucket{application=\"Reactive Order Service\"}[5m])) by (le)) * 1000",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "ms",
          "noValue": "N/A",
          "color": {"mode": "thresholds"},
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "yellow", "value": 500},
              {"color": "red", "value": 2000}
            ]
          }
        }
      }
    },
    {
      "type": "stat",
      "id": 4,
      "title": "App Health",
      "gridPos": {"h": 4, "w": 6, "x": 18, "y": 0},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "up{job=\"reactive-order-service\"}",
          "refId": "A"
        }
      ],
      "options": {
        "graphMode": "none",
        "reduceOptions": {
          "calcs": ["lastNotNull"],
          "fields": "",
          "values": false
        }
      },
      "fieldConfig": {
        "defaults": {
          "color": {"mode": "thresholds"},
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "red", "value": null},
              {"color": "green", "value": 1}
            ]
          },
          "mappings": [
            {
              "type": "value",
              "options": {
                "0": {"text": "DOWN", "index": 0},
                "1": {"text": "UP", "index": 1}
              }
            }
          ]
        }
      }
    },
    {
      "type": "row",
      "id": 5,
      "title": "Order Service Performance",
      "gridPos": {"h": 1, "w": 24, "x": 0, "y": 4},
      "collapsed": false
    },
    {
      "type": "timeseries",
      "id": 6,
      "title": "Order Creation Latency",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 5},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "options": {
        "legend": {"calcs": ["last"], "displayMode": "list", "placement": "bottom"}
      },
      "fieldConfig": {
        "defaults": {
          "unit": "s",
          "custom": {
            "lineWidth": 2,
            "fillOpacity": 10
          }
        }
      },
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "histogram_quantile(0.50, sum(rate(orders_creation_duration_seconds_bucket{application=\"Reactive Order Service\"}[5m])) by (le))",
          "legendFormat": "p50",
          "refId": "A"
        },
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "histogram_quantile(0.95, sum(rate(orders_creation_duration_seconds_bucket{application=\"Reactive Order Service\"}[5m])) by (le))",
          "legendFormat": "p95",
          "refId": "B"
        },
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "histogram_quantile(0.99, sum(rate(orders_creation_duration_seconds_bucket{application=\"Reactive Order Service\"}[5m])) by (le))",
          "legendFormat": "p99",
          "refId": "C"
        }
      ]
    },
    {
      "type": "timeseries",
      "id": 7,
      "title": "HTTP Request Rate by Endpoint",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 5},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "options": {
        "legend": {"calcs": ["last"], "displayMode": "list", "placement": "bottom"}
      },
      "fieldConfig": {
        "defaults": {
          "unit": "reqps",
          "custom": {
            "lineWidth": 2,
            "fillOpacity": 10
          }
        }
      },
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "sum by (method, uri) (rate(http_server_requests_seconds_count{application=\"Reactive Order Service\",uri!~\".*actuator.*\"}[1m]))",
          "legendFormat": "{{method}} {{uri}}",
          "refId": "A"
        }
      ]
    },
    {
      "type": "row",
      "id": 8,
      "title": "Errors & HTTP",
      "gridPos": {"h": 1, "w": 24, "x": 0, "y": 13},
      "collapsed": false
    },
    {
      "type": "timeseries",
      "id": 9,
      "title": "HTTP Errors by Status Code",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 14},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "options": {
        "legend": {"calcs": ["last"], "displayMode": "list", "placement": "bottom"}
      },
      "fieldConfig": {
        "defaults": {
          "unit": "reqps"
        }
      },
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "sum by (status) (rate(http_server_requests_seconds_count{application=\"Reactive Order Service\",status=~\"[45]..\"}[5m]))",
          "legendFormat": "HTTP {{status}}",
          "refId": "A"
        }
      ]
    },
    {
      "type": "timeseries",
      "id": 10,
      "title": "HTTP p95 Latency by Endpoint",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 14},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "options": {
        "legend": {"calcs": ["last"], "displayMode": "list", "placement": "bottom"}
      },
      "fieldConfig": {
        "defaults": {
          "unit": "s"
        }
      },
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "histogram_quantile(0.95, sum by (uri, le) (rate(http_server_requests_seconds_bucket{application=\"Reactive Order Service\",uri!~\".*actuator.*\"}[5m])))",
          "legendFormat": "p95 {{uri}}",
          "refId": "A"
        }
      ]
    },
    {
      "type": "row",
      "id": 11,
      "title": "JVM & Resources",
      "gridPos": {"h": 1, "w": 24, "x": 0, "y": 22},
      "collapsed": false
    },
    {
      "type": "gauge",
      "id": 12,
      "title": "JVM Heap Usage",
      "gridPos": {"h": 8, "w": 6, "x": 0, "y": 23},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "sum(jvm_memory_used_bytes{application=\"Reactive Order Service\",area=\"heap\"}) / sum(jvm_memory_max_bytes{application=\"Reactive Order Service\",area=\"heap\"}) * 100",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "min": 0,
          "max": 100,
          "color": {"mode": "thresholds"},
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "yellow", "value": 70},
              {"color": "red", "value": 90}
            ]
          }
        }
      }
    },
    {
      "type": "gauge",
      "id": 13,
      "title": "CPU Usage",
      "gridPos": {"h": 8, "w": 6, "x": 6, "y": 23},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "process_cpu_usage{application=\"Reactive Order Service\"} * 100",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "min": 0,
          "max": 100,
          "color": {"mode": "thresholds"},
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "yellow", "value": 70},
              {"color": "red", "value": 90}
            ]
          }
        }
      }
    },
    {
      "type": "stat",
      "id": 14,
      "title": "Live Threads",
      "gridPos": {"h": 4, "w": 6, "x": 12, "y": 23},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "jvm_threads_live_threads{application=\"Reactive Order Service\"}",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "short",
          "color": {"mode": "fixed", "fixedColor": "blue"}
        }
      }
    },
    {
      "type": "stat",
      "id": 15,
      "title": "Process Uptime",
      "gridPos": {"h": 4, "w": 6, "x": 18, "y": 23},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "process_uptime_seconds{application=\"Reactive Order Service\"}",
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "s",
          "color": {"mode": "fixed", "fixedColor": "blue"}
        }
      }
    },
    {
      "type": "timeseries",
      "id": 16,
      "title": "JVM Memory",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 27},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "options": {
        "legend": {"calcs": ["last"], "displayMode": "list", "placement": "bottom"}
      },
      "fieldConfig": {
        "defaults": {
          "unit": "bytes"
        }
      },
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "sum(jvm_memory_used_bytes{application=\"Reactive Order Service\",area=\"heap\"})",
          "legendFormat": "Heap Used",
          "refId": "A"
        },
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "sum(jvm_memory_max_bytes{application=\"Reactive Order Service\",area=\"heap\"})",
          "legendFormat": "Heap Max",
          "refId": "B"
        },
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "sum(jvm_memory_used_bytes{application=\"Reactive Order Service\",area=\"nonheap\"})",
          "legendFormat": "Non-Heap Used",
          "refId": "C"
        }
      ]
    },
    {
      "type": "timeseries",
      "id": 17,
      "title": "GC Pause Duration",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 27},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "options": {
        "legend": {"calcs": ["last"], "displayMode": "list", "placement": "bottom"}
      },
      "fieldConfig": {
        "defaults": {
          "unit": "s"
        }
      },
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "rate(jvm_gc_pause_seconds_sum{application=\"Reactive Order Service\"}[5m])",
          "legendFormat": "{{action}} ({{cause}})",
          "refId": "A"
        }
      ]
    },
    {
      "type": "row",
      "id": 18,
      "title": "Database & Resilience",
      "gridPos": {"h": 1, "w": 24, "x": 0, "y": 35},
      "collapsed": false
    },
    {
      "type": "timeseries",
      "id": 19,
      "title": "R2DBC Connection Pool",
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 36},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "options": {
        "legend": {"calcs": ["last"], "displayMode": "list", "placement": "bottom"}
      },
      "fieldConfig": {
        "defaults": {
          "unit": "short"
        }
      },
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "r2dbc_pool_acquired{application=\"Reactive Order Service\"}",
          "legendFormat": "Acquired",
          "refId": "A"
        },
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "r2dbc_pool_max_allocated{application=\"Reactive Order Service\"}",
          "legendFormat": "Max",
          "refId": "B"
        },
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "r2dbc_pool_pending{application=\"Reactive Order Service\"}",
          "legendFormat": "Pending",
          "refId": "C"
        }
      ]
    },
    {
      "type": "timeseries",
      "id": 20,
      "title": "Resilience4j Retries",
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 36},
      "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
      "options": {
        "legend": {"calcs": ["last"], "displayMode": "list", "placement": "bottom"}
      },
      "fieldConfig": {
        "defaults": {
          "unit": "short"
        }
      },
      "targets": [
        {
          "datasource": {"type": "prometheus", "uid": "${datasource_uid}"},
          "expr": "rate(resilience4j_retry_calls_total{application=\"Reactive Order Service\"}[5m])",
          "legendFormat": "{{kind}} ({{name}})",
          "refId": "A"
        }
      ]
    }
  ]
}
