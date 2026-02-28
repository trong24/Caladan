output "ssh_metrics" {
  description = "SSH to metrics instance via IAP only (no public IP)"
  value       = "gcloud compute ssh ${google_compute_instance.metrics.name} --zone=${var.zone} --project=${var.project_id} --tunnel-through-iap"
}

output "ssh_probe" {
  description = "SSH to probe instance via IAP only (no public IP)"
  value       = "gcloud compute ssh ${google_compute_instance.probe.name} --zone=${var.zone} --project=${var.project_id} --tunnel-through-iap"
}

output "iap_tunnel_metrics" {
  description = "Start IAP TCP tunnel to metrics port 8080; then curl http://localhost:8080/metrics"
  value       = "gcloud compute start-iap-tunnel ${google_compute_instance.metrics.name} 8080 --local-host-port=localhost:8080 --zone=${var.zone} --project=${var.project_id}"
}
