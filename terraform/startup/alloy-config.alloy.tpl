// Scrape local metrics from the metrics container.
prometheus.scrape "metrics" {
  targets = [{
    __address__ = "127.0.0.1:8080",
    __path__    = "/metrics",
  }]
  forward_to = [prometheus.remote_write.grafanacloud.receiver]
}

// Remote write to Grafana Cloud. Password is read from ENV (not stored in state).
prometheus.remote_write "grafanacloud" {
  endpoint {
    url = "https://prometheus-blocks-prod-us-central1.grafana.net/api/prom/push"

    basic_auth {
      username = "107395"
      password = env("GRAFANA_CLOUD_PROMETHEUS_PASSWORD")
    }
  }
}
