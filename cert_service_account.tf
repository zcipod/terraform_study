// generate Service Account Certificate
resource "tls_private_key" "service-account" {
  algorithm = "RSA"
}

resource "tls_cert_request" "service-account" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.service-account.private_key_pem

  subject {
    common_name = "service-account"
    organization = "Kubernetes"
    organizational_unit = "Kubernetes The Hard Way"
    country = "AU"
    province = "NSW"
    locality = "Sydney"
  }
}

resource "tls_locally_signed_cert" "service-account" {
  cert_request_pem   = tls_cert_request.service-account.cert_request_pem
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

//resource "local_file" "service-account-pem" {
//  filename = "certs/service-account.pem"
//  sensitive_content = tls_locally_signed_cert.service-account.cert_pem
//}
//
//resource "local_file" "service-account-key-pem" {
//  filename = "certs/service-account-key.pem"
//  sensitive_content = tls_private_key.service-account.private_key_pem
//}
