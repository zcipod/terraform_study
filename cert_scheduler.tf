// generate Kube Scheduler Certificate
resource "tls_private_key" "scheduler" {
  algorithm = "RSA"
}

resource "tls_cert_request" "scheduler" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.scheduler.private_key_pem

  subject {
    common_name = "system:kube-scheduler"
    organization = "system:kube-scheduler"
    organizational_unit = "Kubernetes The Hard Way"
    country = "AU"
    province = "NSW"
    locality = "Sydney"
  }
}

resource "tls_locally_signed_cert" "scheduler" {
  cert_request_pem   = tls_cert_request.scheduler.cert_request_pem
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

//resource "local_file" "scheduler-pem" {
//  filename = "certs/kube-scheduler.pem"
//  sensitive_content = tls_locally_signed_cert.scheduler.cert_pem
//}
//
//resource "local_file" "scheduler-key-pem" {
//  filename = "certs/kube-scheduler-key.pem"
//  sensitive_content = tls_private_key.scheduler.private_key_pem
//}
