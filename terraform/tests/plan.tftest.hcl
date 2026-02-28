# Plan-mode test: validate configuration without creating resources.
# Run from terraform/: terraform test

variables {
  project_id = "my-test-project"
}

run "default_instance_configuration" {
  command = plan

  assert {
    condition     = google_compute_instance.metrics.machine_type == var.machine_type
    error_message = "Metrics instance machine_type should match variable (default e2-micro)."
  }

  assert {
    condition     = google_compute_instance.probe.machine_type == var.machine_type
    error_message = "Probe instance machine_type should match variable (default e2-micro)."
  }

  assert {
    condition     = google_compute_instance.metrics.name == "${var.project_name}-metrics"
    error_message = "Metrics instance name should match project_name."
  }

  assert {
    condition     = google_compute_instance.probe.name == "${var.project_name}-probe"
    error_message = "Probe instance name should match project_name."
  }

  assert {
    condition     = contains(google_compute_instance.metrics.tags, "metrics")
    error_message = "Metrics instance should have metrics network tag."
  }

  assert {
    condition     = contains(google_compute_instance.probe.tags, "probe")
    error_message = "Probe instance should have probe network tag."
  }
}
