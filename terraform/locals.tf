locals {
  common_labels = {
    project    = var.project_name
    managed_by = "terraform"
  }
  # IAP TCP forwarding source range (required for SSH and metrics tunnel)
  iap_cidr = "35.235.240.0/20"
  # Container image for metrics app
  metrics_image = var.metrics_image != "" ? var.metrics_image : "gcr.io/${var.project_id}/metrics:latest"
  # Container image for probe server
  probe_server_image = var.probe_server_image != "" ? var.probe_server_image : "gcr.io/${var.project_id}/probe-server:latest"
}
