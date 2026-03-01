variable "machine_type" {
  description = "GCP machine type for compute instances"
  type        = string
  default     = "e2-micro"

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.machine_type))
    error_message = "Machine type must be a valid GCP machine type format (e.g., e2-micro, n1-standard-1)."
  }
}

variable "project_id" {
  description = "GCP project ID where resources will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be a valid GCP project ID (lowercase, alphanumeric with hyphens, 6-30 chars)."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and labels (lowercase, alphanumeric with hyphens)"
  type        = string
  default     = "caladan"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must start with a letter, contain only lowercase alphanumeric characters and hyphens, and end with alphanumeric."
  }
}

variable "region" {
  description = "GCP region for resources (e.g., asia-southeast1, us-central1)"
  type        = string
  default     = "asia-southeast1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+\\d+$", var.region))
    error_message = "Region must be a valid GCP region format (e.g., asia-southeast1)."
  }
}

variable "zone" {
  description = "GCP zone for compute instances (e.g., asia-southeast1-a)"
  type        = string
  default     = "asia-southeast1-a"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+\\d+-[a-z]$", var.zone))
    error_message = "Zone must be a valid GCP zone format (e.g., asia-southeast1-a)."
  }
}

variable "metrics_image" {
  description = "Container image for the metrics app. If empty, defaults to gcr.io/PROJECT_ID/metrics:latest"
  type        = string
  default     = ""

  validation {
    condition     = var.metrics_image == "" || can(regex("^[a-z0-9\\-.:/@]+$", var.metrics_image))
    error_message = "Metrics image must be empty or a valid container image reference (e.g., gcr.io/project/metrics:latest)."
  }
}

variable "probe_server_image" {
  description = "Container image for the probe server (distroless). If empty, defaults to gcr.io/PROJECT_ID/probe-server:latest"
  type        = string
  default     = ""

  validation {
    condition     = var.probe_server_image == "" || can(regex("^[a-z0-9\\-.:/@]+$", var.probe_server_image))
    error_message = "Probe server image must be empty or a valid container image reference (e.g., gcr.io/project/probe-server:latest)."
  }
}

variable "grafana_cloud_prometheus_password" {
  description = "Grafana Cloud Prometheus remote_write API token. Stored in state (redacted in logs); use a state backend with encryption at rest (e.g. GCS, Terraform Cloud). Leave empty to use instance metadata instead (set grafana_cloud_prometheus_password attribute)."
  type        = string
  default     = ""
  sensitive   = true
}
