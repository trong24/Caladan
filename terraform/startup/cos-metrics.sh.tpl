#!/bin/bash
set -e
/usr/bin/docker-credential-gcr configure-docker || true
/usr/bin/docker pull ${metrics_image}
/usr/bin/docker run -d --restart=always -p 8080:8080 --name metrics \
  -e TARGET_HOST="${probe_host}" \
  -e TARGET_PORT="${probe_port}" \
  -e METRICS_PORT=8080 \
  -e PROBE_INTERVAL_SEC=15 \
  ${metrics_image}

# Grafana Cloud Prometheus password: from Terraform (base64) or from instance metadata.
if [ -n "${grafana_pw_b64}" ]; then
  export GRAFANA_CLOUD_PROMETHEUS_PASSWORD="$(echo "${grafana_pw_b64}" | base64 -d)"
else
  GRAFANA_PW=$(curl -sf -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/grafana_cloud_prometheus_password" 2>/dev/null) && export GRAFANA_CLOUD_PROMETHEUS_PASSWORD="$GRAFANA_PW" || true
fi

# Alloy: scrape local metrics and remote_write to Grafana Cloud (password from ENV).
mkdir -p /etc/alloy
cat > /etc/alloy/config.alloy << ALLOY_EOF
${alloy_config}
ALLOY_EOF
/usr/bin/docker pull grafana/alloy:v1.13.2
/usr/bin/docker run -d --restart=always --name alloy --network=host \
  -v /etc/alloy:/etc/alloy \
  -e GRAFANA_CLOUD_PROMETHEUS_PASSWORD \
  grafana/alloy:v1.13.2 run --server.http.listen-addr=0.0.0.0:12345 --storage.path=/var/lib/alloy/data /etc/alloy/config.alloy
