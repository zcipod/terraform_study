provider "kubernetes" {
  load_config_file = false

  host = "https://${google_compute_address.public_address.address}:6443"
  username = "admin"

  client_certificate     = tls_locally_signed_cert.admin.cert_pem
  client_key             = tls_private_key.admin.private_key_pem
  cluster_ca_certificate = tls_self_signed_cert.ca.cert_pem
}

resource "kubernetes_deployment" "nginx" {
  depends_on = [google_compute_instance.worker[0], google_compute_instance.controller[0]]
  metadata {
    name = "scalable-nginx-example"
    labels = {
      App = "ScalableNginxExample"
    }
  }

  spec {
    replicas = 1
    min_ready_seconds = 60
    selector {
      match_labels = {
        App = "ScalableNginxExample"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableNginxExample"
        }
      }
      spec {
        container {
          image = "nginx:1.7.8"
          name  = "example"

          port {
            container_port = 80
          }

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-example"
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

