// generate Admin Client Certificate
resource "tls_private_key" "admin" {
  algorithm = "RSA"
}

resource "tls_cert_request" "admin" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.admin.private_key_pem

  subject {
    common_name = "admin"
    organization = "system:masters"
    organizational_unit = "Kubernetes The Hard Way"
    country = "AU"
    province = "NSW"
    locality = "Sydney"
  }
}

resource "tls_locally_signed_cert" "admin" {
  cert_request_pem   = tls_cert_request.admin.cert_request_pem
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

//resource "local_file" "admin-pem" {
//  filename = "certs/admin.pem"
//  sensitive_content = tls_locally_signed_cert.admin.cert_pem
//}
//
//resource "local_file" "admin-key-pem" {
//  filename = "certs/admin-key.pem"
//  sensitive_content = tls_private_key.admin.private_key_pem
//}