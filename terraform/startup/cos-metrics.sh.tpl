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
