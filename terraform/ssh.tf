resource "tls_private_key" "main" {
  algorithm   = "RSA"
  rsa_bits    = 2048
}