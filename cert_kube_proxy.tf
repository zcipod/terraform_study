// generate Kube Proxy Certificate
resource "tls_private_key" "proxy" {
  algorithm = "RSA"
}

resource "tls_cert_request" "proxy" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.proxy.private_key_pem

  subject {
    common_name = "system:kube-proxy"
    organization = "system:node-proxier"
    organizational_unit = "Kubernetes The Hard Way"
    country = "AU"
    province = "NSW"
    locality = "Sydney"
  }
}

resource "tls_locally_signed_cert" "proxy" {
  cert_request_pem   = tls_cert_request.proxy.cert_request_pem
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

resource "local_file" "proxy-pem" {
  filename = "certs/kube-proxy.pem"
  sensitive_content = tls_locally_signed_cert.proxy.cert_pem
}

resource "local_file" "proxy-key-pem" {
  filename = "certs/kube-proxy-key.pem"
  sensitive_content = tls_private_key.proxy.private_key_pem
}

//data "archive_file" "proxy-key-pair" {
//  type = "zip"
//  output_path = "tf-result/proxy.zip"
//  source {
//    content = tls_private_key.proxy.private_key_pem
//    filename = "kube-proxy.key.pem"
//  }
//  source {
//    content = tls_locally_signed_cert.proxy.cert_pem
//    filename = "kube-proxy.pem"
//  }
//}