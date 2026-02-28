## Overview

- **Metrics instance**: Runs the metrics app as a **container** performing HTTP GETs to the probe every 15 seconds and serving Prometheus-style metrics on port 8080 at **`/metrics`**.
- **Probe instance**: Runs a minimal HTTP server **container** on port 8081 so the metrics instance can measure round-trip time.

Both instances use **Container-Optimized OS**; the app is packaged as a **Docker image** and run via startup script (`docker run`). Provisioning is done with **Terraform**. Instances have **private IPs only**; outbound internet uses **Cloud NAT**, and **SSH and metrics access are via IAP** only.

## Prerequisites

- **Terraform** >= v1.14.6
- **Google Cloud**: A GCP project with the Compute Engine API enabled. Authenticate via `gcloud auth login`.
- **Docker** if want to run the app locally.

## How to Provision and Deploy

1. **Enable APIs**:
   ```bash
   gcloud services enable compute.googleapis.com containerregistry.googleapis.com storage.googleapis.com --project=YOUR_PROJECT_ID
   ```

2. **Build and push both Docker images** (required before instances can start):
   Default Terraform images are `gcr.io/<project_id>/metrics:latest` and `gcr.io/<project_id>/probe-server:latest`.

   **Alternatively**, the repo’s GitHub Action (on push to `main`) builds and pushes images to **GitHub Container Registry**.GCP COS must be able to pull from GHCR.

3. **Apply Terraform** (first run uses local state; migrate to GCS next):
   ```bash
   cd terraform
   terraform init
   terraform plan   #using terraform.tfvars
   terraform apply
   ```
   Validate without applying, run `terraform test` from `terraform/`.

   **Move local state to GCS bucket** (after first apply): Terraform creates a GCS bucket with versioning for state. To use it:
   ```bash
   # 1. Copy the example backend config and set your project ID
   cp backend.tf.example backend.tf
   # Edit backend.tf: replace YOUR_PROJECT_ID with your GCP project ID (e.g. caladan-488808).

   # 2. Re-initialize and migrate state from local to GCS
   terraform init -migrate-state
   ```
   After migration, state is stored in `gs://YOUR_PROJECT_ID-tfstate/terraform/state/default.tfstate` with versioning enabled.

4. **Wait for startup** (about 1–2 minutes). COS instances pull the images, and start the containers. Outbound traffic uses **Cloud NAT**.

5. **Verify** (instances have **no public IPs**; use IAP only):
   - **SSH**:
     ```
     gcloud compute ssh caladan-metrics --zone=asia-southeast1-a --project=caladan-488808 --tunnel-through-iap"
     gcloud compute ssh caladan-probe --zone=asia-southeast1-a --project=caladan-488808 --tunnel-through-iap"
     ```

## Technology Choices and Rationale

| Choice | Rationale |
|--------|-----------|
| **Terraform** | Declarative IaC, strong Google provider, fits the “provision two servers” requirement. |
| **GCP + default network** | Default VPC keeps the demo simple. **Cloud NAT** gives instances outbound internet without public IPs. **IAP only** for SSH and metrics (firewall allows 22 and 8080 from 35.235.240.0/20 only); probe 8081 from metrics→probe only. |
| **Python app in Docker** | App is Python packaged as a Docker minimal image, no shell. |
| **Container-Optimized OS** | Both VMs run COS; startup script runs `docker run` for the metrics and the probe-server image |
| **HTTP-based latency** | HTTP GET to the probe is reliable and easy to implement. |
| **Prometheus-style `/metrics`** | Single HTTP endpoint for latency metrics; familiar format. |

## How to Access and Interpret the Latency Metrics

- **URL**: Instances are private-only. Use IAP TCP tunnel: run `terraform output -raw iap_tunnel_metrics`, then `curl http://localhost:8080/metrics`.
- **Port**: 8080 (configurable via app env; startup script sets it to 8080).

   - **Metrics**: Start an IAP TCP tunnel, then curl locally:
     ```bash
     gcloud compute start-iap-tunnel caladan-metrics 8080 --local-host-port=localhost:8080 --zone=asia-southeast1-a --project=caladan-488808
     WARNING:

     To increase the performance of the tunnel, consider installing NumPy. For instructions,
     please see https://cloud.google.com/iap/docs/using-tcp-forwarding#increasing_the_tcp_upload_bandwidth

     Testing if tunnel connection works.
     Listening on port [8080].
     ```
   - **In another terminal**:
     ```
     curl 127.0.0.1:8080/metrics
     # HELP latency_seconds HTTP round-trip latency to target
     # TYPE latency_seconds gauge
     latency_seconds 0.003545
     # HELP latency_measurements_total Total number of measurements
     # TYPE latency_measurements_total counter
     latency_measurements_total 704
     # HELP latency_last_success_timestamp_seconds Unix time of last successful measurement
     # TYPE latency_last_success_timestamp_seconds gauge
     latency_last_success_timestamp_seconds 1772285144
     ```

- **`latency_seconds`**: Last measured HTTP round-trip time (seconds) from metrics to probe.
- **`latency_measurements_total`**: Total number of probe attempts since the app started.
- **`latency_last_success_timestamp_seconds`**: Unix timestamp of the last successful measurement.
