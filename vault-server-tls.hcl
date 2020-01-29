ui = false

listener "tcp" {
  address          = "127.0.0.1:8200"
  tls_disable      = "false"
  tls_require_and_verify_client_cert="true"
  tls_cert_file = "./output/server-certs/vaultcert.pem"
  tls_key_file  = "./output/server-certs/vault_key.pem"
  # This is the certificate that client certs are signed with.  In this demo
  # the same intermediate cert signs both Vault and Client certs.  But 
  # to show this differentiation, we use the ca out of the /client-certs/ dir
  tls_client_ca_file="./output/client-certs/ca.pem"
}

api_addr="https://127.0.0.1:8200"
storage "file" {
  path = "/var/tmp/vault-ssl-demo-data"
}