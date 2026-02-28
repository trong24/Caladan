#!/bin/bash
set -e
/usr/bin/docker-credential-gcr configure-docker || true
/usr/bin/docker pull ${probe_image}
/usr/bin/docker run -d --restart=always -p 8081:8081 --name probe \
  ${probe_image}
