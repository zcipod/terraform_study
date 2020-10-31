// generate CA including ca.pem and ca-key.pem
resource "tls_private_key" "ca" {
  algorithm = "RSA"
}
resource "tls_self_signed_cert" "ca" {
  key_algorithm = tls_private_key.ca.algorithm
  private_key_pem = tls_private_key.ca.private_key_pem

  # Certificate expires after 12 hours.
  validity_period_hours = 8760

  is_ca_certificate = true

  allowed_uses = [
  "key_encipherment",
  "cert_signing",
  "server_auth",
  "client_auth"
  ]

  subject {
    common_name = "Kubernetes"
    organization = "Kubernetes"
    organizational_unit = "CA"
    country = "AU"
    province = "NSW"
    locality = "Sydney"
  }
}

resource "local_file" "ca-pem" {
  filename = "certs/ca.pem"
  sensitive_content = tls_self_signed_cert.ca.cert_pem
}

resource "local_file" "ca-key-pem" {
  filename = "certs/ca-key.pem"
  sensitive_content = tls_private_key.ca.private_key_pem
}


//data "archive_file" "ca-key-pair" {
//  type = "zip"
//  output_path = "tf-result/ca.zip"
//  source {
//  content = tls_private_key.ca.private_key_pem
//  filename = "ca-key.pem"
//  }
//  source {
//  content = tls_self_signed_cert.ca.cert_pem
//  filename = "ca.pem"
//  }
//}