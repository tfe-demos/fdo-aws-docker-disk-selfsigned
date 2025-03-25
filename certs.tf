# Create CA key
resource "tls_private_key" "ca_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}
# Export CA key
resource "local_file" "ca_key" {
  content  = tls_private_key.ca_key.private_key_pem
  filename = "tfeparty/ca-key.pem"
}
# Create CA Cert
resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem   = tls_private_key.ca_key.private_key_pem
  is_ca_certificate = true
  subject {
    country             = "NL"
    province            = "Noord"
    locality            = "Amsterdam"
    common_name         = "Root CA"
    organization        = "Hashicorp"
    organizational_unit = "TFE"
  }
  validity_period_hours = 43800 # 5 years
  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing"
  ]
}
# Export CA Cert
resource "local_file" "ca_cert" {
  content  = tls_self_signed_cert.ca_cert.cert_pem
  filename = "tfeparty/bundle.pem"
}

###########################################################################################

# Create TFE Key
resource "tls_private_key" "tfe_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}
# Export TFE Key
resource "local_file" "tfe_key" {
  content  = tls_private_key.tfe_key.private_key_pem
  filename = "tfeparty/key.pem"
}
# Create CSR for TFE Cert
resource "tls_cert_request" "tfe_csr" {
  private_key_pem = tls_private_key.tfe_key.private_key_pem
  dns_names       = ["${aws_instance.ubuntu.public_dns}", "localhost", "tfeparty.cfd"]
  ip_addresses    = ["${aws_instance.ubuntu.public_ip}", "${aws_instance.ubuntu.private_ip}", "127.0.0.1"]
  subject {
    common_name = aws_instance.ubuntu.public_dns
  }
}
# Create TFE Cert
resource "tls_locally_signed_cert" "tfe_cert" {
  cert_request_pem      = tls_cert_request.tfe_csr.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca_key.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca_cert.cert_pem
  validity_period_hours = 8766 # 1 year
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
  set_subject_key_id = true
}
# Export TFE Cert
resource "local_file" "tfe_cert" {
  content  = tls_locally_signed_cert.tfe_cert.cert_pem
  filename = "tfeparty/cert.pem"
}