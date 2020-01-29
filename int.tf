resource "vault_mount" "pki_int" {
    type = "pki"
    path = "pki-int-ca"
    default_lease_ttl_seconds = 63072000 # 2 years
    max_lease_ttl_seconds = 63072000 # 2 years
    description = "Intermediate Authority for ${var.server_cert_domain}"
}
# Step 1
# Create a CSR (Certificate Signing Request)
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  depends_on = [ vault_mount.pki_int ]

  backend = vault_mount.pki_int.path
  #backend = vault_mount.root.path
  type = "internal"
  # This appears to be overwritten when the CA signs this cert, I'm not sure 
  # the importance of common_name here.
  common_name = "${var.server_cert_domain} Intermediate Certificate"
  format = "pem"
  private_key_format = "der"
  key_type = "rsa"
  key_bits = "4096"
}
# Step 2
# Have the Root CA Sign our CSR
resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  depends_on = [ vault_pki_secret_backend_intermediate_cert_request.intermediate, vault_pki_secret_backend_config_ca.ca_config ]
  backend = vault_mount.root.path

  csr = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name = "${var.server_cert_domain} Intermediate Certificate"
  exclude_cn_from_sans = true
  ou = "Development"
  organization = "mydomain.com"
  # Note that I am asking for 8 years here, since the vault_mount.root has a max_lease_ttl of 5 years
  # this 8 year request is shortened to 5.
  ttl = 252288000 #8 years
 
}
resource local_file signed_intermediate {
    sensitive_content = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
    filename = "${path.root}/output/int_ca/int_cert.pem"
    file_permission = "0400"
}


# Step 3
# Now that CSR is processed and we have a signed cert
# Put the Certificate, and The Root CA into the backend 
# mount point.  IF you do not put the CA in here, the 
# chained_ca output of a generated cert will only be 
# the intermedaite cert and not the whole chain.
resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" { 
 backend = vault_mount.pki_int.path

 certificate = "${vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate}\n${tls_self_signed_cert.ca_cert.cert_pem}"
}

output "ca_cert_chain"  {
    value = vault_pki_secret_backend_root_sign_intermediate.intermediate.ca_chain
}

output "intermediate_ca" {
    value = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

output "intermediate_key"  {
    value = "${vault_pki_secret_backend_intermediate_cert_request.intermediate.private_key}"
}