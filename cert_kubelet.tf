// generate Kubelet Client Certificate
resource "tls_private_key" "kubelet" {
  algorithm = "RSA"
  count = var.WORKER_NUM
}

resource "tls_cert_request" "kubelet" {
  count = var.WORKER_NUM
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.kubelet[count.index].private_key_pem

  dns_names = ["${var.WORKER_NAME}-${count.index}"]
  ip_addresses = [
    google_compute_instance.worker[count.index].network_interface[0].network_ip,
                  google_compute_instance.worker[count.index].network_interface[0].access_config[0].nat_ip]

  subject {
    common_name = "system:node:${var.WORKER_NAME}-${count.index}"
    organization = "system:nodes"
    organizational_unit = "Kubernetes The Hard Way"
    country = "AU"
    province = "NSW"
    locality = "Sydney"
  }
}

resource "tls_locally_signed_cert" "kubelet" {
  count = var.WORKER_NUM
  cert_request_pem   = tls_cert_request.kubelet[count.index].cert_request_pem
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

data "archive_file" "kubelet-key-pair" {
  count = var.WORKER_NUM
  type = "zip"
  output_path = "tf-result/${var.WORKER_NAME}-${count.index}.zip"
  source {
    content = tls_private_key.kubelet[count.index].private_key_pem
    filename = "${var.WORKER_NAME}-${count.index}.key.pem"
  }
  source {
    content = tls_locally_signed_cert.kubelet[count.index].cert_pem
    filename = "${var.WORKER_NAME}-${count.index}.pem"
  }
}