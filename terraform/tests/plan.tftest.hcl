# Plan-mode test: validate configuration without creating resources.
# Run from terraform/: terraform test
# Tests validate resource naming, network configuration, tags, labels, and firewall rules

variables {
  project_id = "caladan-488808"
}

run "default_instance_configuration" {
  command = plan

  # ========================================================================
  # Instance Configuration Tests
  # ========================================================================

  assert {
    condition     = google_compute_instance.metrics.machine_type == var.machine_type
    error_message = "Metrics instance machine_type should match variable (default: e2-micro)."
  }

  assert {
    condition     = google_compute_instance.probe.machine_type == var.machine_type
    error_message = "Probe instance machine_type should match variable (default: e2-micro)."
  }

  assert {
    condition     = google_compute_instance.metrics.machine_type == "e2-micro"
    error_message = "Metrics instance should use default machine type e2-micro."
  }

  assert {
    condition     = google_compute_instance.probe.machine_type == "e2-micro"
    error_message = "Probe instance should use default machine type e2-micro."
  }

  # ========================================================================
  # Resource Naming Tests
  # ========================================================================

  assert {
    condition     = google_compute_instance.metrics.name == "${var.project_name}-metrics"
    error_message = "Metrics instance name should be 'caladan-metrics'."
  }

  assert {
    condition     = google_compute_instance.probe.name == "${var.project_name}-probe"
    error_message = "Probe instance name should be 'caladan-probe'."
  }

  # ========================================================================
  # Network Configuration Tests
  # ========================================================================

  assert {
    condition     = google_compute_instance.metrics.network_interface[0].network == "default"
    error_message = "Metrics instance should use default network."
  }

  assert {
    condition     = google_compute_instance.probe.network_interface[0].network == "default"
    error_message = "Probe instance should use default network."
  }

  assert {
    condition     = length(google_compute_instance.metrics.network_interface) > 0 && google_compute_instance.metrics.network_interface[0].access_config == []
    error_message = "Metrics instance should have no public IP (private only)."
  }

  assert {
    condition     = length(google_compute_instance.probe.network_interface) > 0 && google_compute_instance.probe.network_interface[0].access_config == []
    error_message = "Probe instance should have no public IP (private only)."
  }

  # ========================================================================
  # Network Tags Tests (used by firewall rules)
  # ========================================================================

  assert {
    condition     = contains(google_compute_instance.metrics.tags, "metrics")
    error_message = "Metrics instance must have 'metrics' network tag for firewall rules."
  }

  assert {
    condition     = contains(google_compute_instance.probe.tags, "probe")
    error_message = "Probe instance must have 'probe' network tag for firewall rules."
  }

  assert {
    condition     = length(google_compute_instance.metrics.tags) == 1
    error_message = "Metrics instance should have exactly one network tag."
  }

  assert {
    condition     = length(google_compute_instance.probe.tags) == 1
    error_message = "Probe instance should have exactly one network tag."
  }

  # ========================================================================
  # Labels Tests
  # ========================================================================

  assert {
    condition     = google_compute_instance.metrics.labels["project"] == var.project_name
    error_message = "Metrics instance should have 'project' label set to project_name."
  }

  assert {
    condition     = google_compute_instance.probe.labels["project"] == var.project_name
    error_message = "Probe instance should have 'project' label set to project_name."
  }

  assert {
    condition     = google_compute_instance.metrics.labels["managed_by"] == "terraform"
    error_message = "Metrics instance should have 'managed_by' label set to 'terraform'."
  }

  assert {
    condition     = google_compute_instance.probe.labels["managed_by"] == "terraform"
    error_message = "Probe instance should have 'managed_by' label set to 'terraform'."
  }

  # ========================================================================
  # Startup Script Tests
  # ========================================================================

  assert {
    condition     = google_compute_instance.metrics.metadata_startup_script != null && google_compute_instance.metrics.metadata_startup_script != ""
    error_message = "Metrics instance must have a startup script configured."
  }

  assert {
    condition     = google_compute_instance.probe.metadata_startup_script != null && google_compute_instance.probe.metadata_startup_script != ""
    error_message = "Probe instance must have a startup script configured."
  }

  # ========================================================================
  # Boot Disk Tests
  # ========================================================================

  assert {
    condition     = google_compute_instance.metrics.boot_disk[0].initialize_params[0].image != null
    error_message = "Metrics instance must have boot disk image configured."
  }

  assert {
    condition     = google_compute_instance.probe.boot_disk[0].initialize_params[0].image != null
    error_message = "Probe instance must have boot disk image configured."
  }

  # ========================================================================
  # Firewall Rules Tests
  # ========================================================================

  assert {
    condition     = google_compute_firewall.allow_ssh_iap.network == "default"
    error_message = "SSH firewall rule should apply to default network."
  }

  assert {
    condition     = google_compute_firewall.allow_ssh_iap.allow[0].protocol == "tcp"
    error_message = "SSH firewall rule should allow TCP protocol."
  }

  assert {
    condition     = contains(google_compute_firewall.allow_ssh_iap.allow[0].ports, "22")
    error_message = "SSH firewall rule should allow port 22."
  }

  assert {
    condition     = contains(google_compute_firewall.allow_ssh_iap.source_ranges, "35.235.240.0/20")
    error_message = "SSH firewall rule should restrict source to IAP CIDR range (35.235.240.0/20)."
  }

  assert {
    condition     = google_compute_firewall.allow_metrics_iap.allow[0].protocol == "tcp"
    error_message = "Metrics firewall rule should allow TCP protocol."
  }

  assert {
    condition     = contains(google_compute_firewall.allow_metrics_iap.allow[0].ports, "8080")
    error_message = "Metrics firewall rule should allow port 8080."
  }

  assert {
    condition     = contains(google_compute_firewall.allow_metrics_iap.target_tags, "metrics")
    error_message = "Metrics firewall rule should target 'metrics' instances."
  }

  assert {
    condition     = contains(google_compute_firewall.allow_probe.source_tags, "metrics")
    error_message = "Probe firewall rule should allow traffic from 'metrics' instances."
  }

  assert {
    condition     = contains(google_compute_firewall.allow_probe.target_tags, "probe")
    error_message = "Probe firewall rule should target 'probe' instances."
  }

  assert {
    condition     = contains(google_compute_firewall.allow_probe.allow[0].ports, "8081")
    error_message = "Probe firewall rule should allow port 8081."
  }

  # ========================================================================
  # Cloud NAT Configuration Tests
  # ========================================================================

  assert {
    condition     = google_compute_router.router.network == "default"
    error_message = "Router should be configured for default network."
  }

  assert {
    condition     = google_compute_router_nat.nat.nat_ip_allocate_option == "AUTO_ONLY"
    error_message = "NAT should use AUTO_ONLY IP allocation."
  }

  assert {
    condition     = google_compute_router_nat.nat.source_subnetwork_ip_ranges_to_nat == "ALL_SUBNETWORKS_ALL_IP_RANGES"
    error_message = "NAT should apply to all subnetworks and IP ranges."
  }

  # ========================================================================
  # GCS Bucket Configuration Tests
  # ========================================================================

  assert {
    condition     = google_storage_bucket.tfstate.name == "${var.project_id}-tfstate"
    error_message = "Terraform state bucket name should follow naming convention."
  }

  assert {
    condition     = google_storage_bucket.tfstate.uniform_bucket_level_access == true
    error_message = "Terraform state bucket should have uniform bucket-level access."
  }

  assert {
    condition     = google_storage_bucket.tfstate.versioning[0].enabled == true
    error_message = "Terraform state bucket should have versioning enabled."
  }

  # ========================================================================
  # API Service Dependencies
  # ========================================================================

  assert {
    condition     = google_project_service.iap.service == "iap.googleapis.com"
    error_message = "IAP API should be enabled."
  }

  assert {
    condition     = google_project_service.compute.service == "compute.googleapis.com"
    error_message = "Compute API should be enabled."
  }

  assert {
    condition     = google_project_service.storage.service == "storage.googleapis.com"
    error_message = "Storage API should be enabled."
  }
}
