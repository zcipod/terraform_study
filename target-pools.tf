resource "google_compute_target_pool" "target-pool" {
  name = "kubernetes-target-pool"

  instances = [for i in range(var.CONTROLLER_NUM): "${var.ZONE}/${var.CONTROLLER_NAME}-${i}"]

  health_checks = [
    google_compute_http_health_check.kubernetes.name,
  ]
}