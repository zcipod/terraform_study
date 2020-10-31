resource "google_compute_route" "route" {
  count = var.WORKER_NUM
  name         = "kubernetes-route-10-200-${count.index}-0-24"
  network      = google_compute_network.vpc_network.name
  dest_range   = "10.200.${count.index}.0/24"
  next_hop_ip = "10.240.0.2${count.index}"
  depends_on = [google_compute_subnetwork.subnet]
}