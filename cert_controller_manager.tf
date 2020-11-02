// generate Kube Controller Manager Certificate
resource "tls_private_key" "controller" {
  algorithm = "RSA"
}

resource "tls_cert_request" "controller" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.controller.private_key_pem

  subject {
    common_name = "system:kube-controller-manager"
    organization = "system:kube-controller-manager"
    organizational_unit = "Kubernetes The Hard Way"
    country = "AU"
    province = "NSW"
    locality = "Sydney"
  }
}

resource "tls_locally_signed_cert" "controller" {
  cert_request_pem   = tls_cert_request.controller.cert_request_pem
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

//resource "local_file" "controller-manager-pem" {
//  filename = "certs/kube-controller-manager.pem"
//  sensitive_content = tls_locally_signed_cert.controller.cert_pem
//}
//
//resource "local_file" "controller-manager-key-pem" {
//  filename = "certs/kube-controller-manager-key.pem"
//  sensitive_content = tls_private_key.controller.private_key_pem
//}
