resource "google_compute_forwarding_rule" "forwarding-rule" {
  name       = "kubernetes-forwarding-rule"
  target     = google_compute_target_pool.target-pool.id
  port_range = "6443"
  region = var.REGION
  ip_address = google_compute_address.public_address.address

}