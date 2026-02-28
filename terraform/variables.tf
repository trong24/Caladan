variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-micro"
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and labels"
  type        = string
  default     = "caladan"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-southeast1-a"
}

variable "metrics_image" {
  description = "Container image for the metrics app (metrics instance)"
  type        = string
  default     = "" # Default: gcr.io/PROJECT_ID/metrics:latest
}

variable "probe_server_image" {
  description = "Container image for the probe server (probe instance; distroless)"
  type        = string
  default     = "" # Default: gcr.io/PROJECT_ID/probe-server:latest
}
