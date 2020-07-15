# Create a mount point for the Root Certiifacte authority.
resource "vault_mount" "root" {
    type = "pki"
    path = "pki-root-ca"
    default_lease_ttl_seconds = 31556952 # 1 years
    max_lease_ttl_seconds = 157680000 # 5 years
    description = "Root Certificate Authority"
}

# Modify the mount point and set URLs for the issuer and crl.
resource "vault_pki_secret_backend_config_urls" "config_urls" {
  depends_on = [ vault_mount.root ]  
  backend              = vault_mount.root.path
  issuing_certificates = ["http://vault1.${var.server_cert_domain}:8200/v1/pki/ca"]
  crl_distribution_points= ["http://vault1.${var.server_cert_domain}:8200/v1/pki/crl"]
}

# if you want to create the root cert in VAULT and never expose the 
# private key to the local machine use this route.  However your 
# CA infrastructure is now tied to vault and pretty much the server 
# you created the CA on.
# resource "vault_pki_secret_backend_root_cert" "ca-cert" {
#   depends_on = [vault_pki_secret_backend_config_urls.config_urls]
#   backend = vault_mount.root.path

#   type = "exported"
#   common_name = "${var.server_cert_domain} Root CA"
#   ttl = 473040000 #15 Years
#   format = "pem"
#   private_key_format = "der"
#   key_type = "rsa"
#   key_bits = "2048"
#   exclude_cn_from_sans = true
#   ou = "Developent"
#   organization = "Clinical 6"

# }
# resource local_file ca_file_vault {
#     sensitive_content = vault_pki_secret_backend_root_cert.ca-cert.certificate
#     filename = "${path.root}/output/certs/clinical6_ca_cert.pem"
#     file_permission = "0400"
# }


# Create a private key for use with the Root CA.
resource tls_private_key ca_key {
   algorithm = "RSA"
   rsa_bits = 4096
}
# This is a highly sensitive output of this process.
resource local_file private_key {
    sensitive_content = tls_private_key.ca_key.private_key_pem
    filename = "${path.root}/output/root_ca/ca_key.pem"
    file_permission = "0400"
}

# 
# Create a Self Signed Root Certificate Authority
#
resource tls_self_signed_cert ca_cert {
   private_key_pem = tls_private_key.ca_key.private_key_pem
   key_algorithm = "RSA"
   subject {
     common_name = "${var.server_cert_domain} Root CA"
     organization = "Acme Inc"
     organizational_unit = "Development"
     street_address = ["1234 Main Street"]
     locality = "Beverly Hills"
     province = "CA"
     country = "USA"
     postal_code = "90210"

   }
   # 175200 = 20 years
   validity_period_hours = 175200
   allowed_uses = [
     "cert_signing",
     "crl_signing"
   ]
   is_ca_certificate = true 

}

resource local_file ca_file {
    sensitive_content = tls_self_signed_cert.ca_cert.cert_pem
    filename = "${path.root}/output/root_ca/ca_cert.pem"
    file_permission = "0400"
}
# This PEM bundle is not like most others.  Most PEM bundles are a chain of Certificate Authority Certs.
# This bundle is the Private Key (first), followed by the the Certificate.
resource local_file ca_pem_bundle {
    sensitive_content = "${tls_private_key.ca_key.private_key_pem}${tls_self_signed_cert.ca_cert.cert_pem}"
    filename = "${path.root}/output/root_ca/ca_cert_key_bundle.pem"
    file_permission = "0400"
}

# Take the Root CA certificate that we have created and store it in 
# the mount point pki-root-ca.  The ca_pem_bundle in this case is
# the Certificate we generated and the key for it.
resource "vault_pki_secret_backend_config_ca" "ca_config" {
  depends_on = [ vault_mount.root, tls_private_key.ca_key]  
  backend  = vault_mount.root.path
  pem_bundle = local_file.ca_pem_bundle.sensitive_content
}

