resource "google_compute_http_health_check" "kubernetes" {
  name         = "kubernetes"
  description  = "Kubernetes Health Check"
  host         = "kubernetes.default.svc.cluster.local"
  request_path = "/healthz"
}