// generate Kubelet API Server Certificate
resource "tls_private_key" "api-server" {
  algorithm = "RSA"
}

resource "tls_cert_request" "api-server" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.api-server.private_key_pem

  dns_names = ["kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.svc.cluster.local"]

  ip_addresses = concat(["10.32.0.1",
    "127.0.0.1",
    google_compute_address.public_address.address],
    [for i in range(var.WORKER_NUM): "10.240.0.1${i}"])

  subject {
    common_name = "API Server"
    organization = "Kubernetes"
    organizational_unit = "Kubernetes The Hard Way"
    country = "AU"
    province = "NSW"
    locality = "Sydney"
  }
}

resource "tls_locally_signed_cert" "api-server" {
  cert_request_pem   = tls_cert_request.api-server.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "server_auth",
    "client_auth",
    "digital_signature"
  ]
}

data "archive_file" "api-server-key-pair" {
  type = "zip"
  output_path = "tf-result/api-server.zip"
  source {
    content = tls_private_key.api-server.private_key_pem
    filename = "kube-api-server.key.pem"
  }
  source {
    content = tls_locally_signed_cert.api-server.cert_pem
    filename = "kube-api-server.pem"
  }
}