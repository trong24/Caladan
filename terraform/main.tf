# ------------------------------------------------------------------------------
# APIs
# ------------------------------------------------------------------------------

resource "google_project_service" "iap" {
  project = var.project_id
  service = "iap.googleapis.com"
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"
}

# ------------------------------------------------------------------------------
# GCS bucket for Terraform state
# ------------------------------------------------------------------------------

resource "google_storage_bucket" "tfstate" {
  name     = "${var.project_id}-tfstate"
  project  = var.project_id
  location = var.region

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  depends_on = [google_project_service.storage]
}

# ------------------------------------------------------------------------------
# Cloud NAT (outbound internet for instances with no external IP)
# ------------------------------------------------------------------------------

resource "google_compute_router" "router" {
  name    = "${var.project_name}-router"
  region  = var.region
  network = "default"
}

resource "google_compute_router_nat" "nat" {
  name                                = "${var.project_name}-nat"
  router                              = google_compute_router.router.name
  region                              = google_compute_router.router.region
  nat_ip_allocate_option              = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  enable_endpoint_independent_mapping = false
}

# ------------------------------------------------------------------------------
# Firewall rules
# SSH and metrics only via IAP (35.235.240.0/20); probe from metrics to probe only
# ------------------------------------------------------------------------------

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${var.project_name}-allow-ssh-iap"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [local.iap_cidr]
  description   = "Allow SSH via IAP only (no public IP on instances)"
}

resource "google_compute_firewall" "allow_metrics_iap" {
  name    = "${var.project_name}-allow-metrics-iap"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [local.iap_cidr]
  target_tags   = ["metrics"]
  description   = "Allow metrics endpoint via IAP TCP tunnel only"
}

resource "google_compute_firewall" "allow_probe" {
  name    = "${var.project_name}-allow-probe"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8081"]
  }

  source_tags = ["metrics"]
  target_tags = ["probe"]
  description = "Allow probe from metrics to probe only"
}

# ------------------------------------------------------------------------------
# Container-Optimized OS image
# ------------------------------------------------------------------------------

data "google_compute_image" "cos" {
  family  = "cos-stable"
  project = "cos-cloud"
}

# ------------------------------------------------------------------------------
# Compute Engine instances (Container-Optimized OS; private IP only; outbound via Cloud NAT)
# ------------------------------------------------------------------------------

resource "google_compute_instance" "probe" {
  name         = "${var.project_name}-probe"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
    }
  }

  network_interface {
    network = "default"
    # No access_config: private IP only; outbound via Cloud NAT
  }

  tags = ["probe"]

  labels = local.common_labels

  metadata_startup_script = templatefile("${path.module}/startup/cos-probe.sh.tpl", {
    probe_image = local.probe_server_image
  })

  allow_stopping_for_update = true
}

resource "google_compute_instance" "metrics" {
  name         = "${var.project_name}-metrics"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
    }
  }

  network_interface {
    network = "default"
    # No access_config: private IP only; outbound via Cloud NAT
  }

  tags = ["metrics"]

  labels = local.common_labels

  metadata_startup_script = templatefile("${path.module}/startup/cos-metrics.sh.tpl", {
    probe_host       = google_compute_instance.probe.network_interface[0].network_ip
    probe_port       = "8081"
    metrics_image    = local.metrics_image
    alloy_config     = file("${path.module}/startup/alloy-config.alloy.tpl")
    grafana_pw_b64   = var.grafana_cloud_prometheus_password != "" ? base64encode(var.grafana_cloud_prometheus_password) : ""
  })

  allow_stopping_for_update = true
}
