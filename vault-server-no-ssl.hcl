ui = true


listener "tcp" {
  address          = "127.0.0.1:8200"
  tls_disable      = "true"
  tls_require_and_verify_client_cert="true"
  tls_cert_file = "./output/server-certs/output/ca_.pem"
  tls_key_file  = "./output/server-certs/output/vault_key.pem"
  tls_client_ca_file="./output/client-certs/vaultcacert.pem"
}

api_addr="http://127.0.0.1:8200"

storage "file" {
  path = "/var/tmp/vault-ssl-demo-data"
}