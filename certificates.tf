//resource "tls_private_key" "instance-key" {
//  algorithm = "RSA"
//  rsa_bits = 2048
//}

//resource "tls_self_signed_cert" "example" {
//  key_algorithm   = "RSA"
//
//  subject {
//    common_name  = "example.com"
//    organization = "ACME Examples, Inc"
//  }
//
//  validity_period_hours = 8760
//
//  allowed_uses = [
//    "key_encipherment",
//    "cert_signing",
//    "server_auth",
//    "client_auth"
//  ]
//  private_key_pem = file("private_key.pem")
//  is_ca_certificate = true
//}