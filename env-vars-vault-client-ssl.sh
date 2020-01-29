#!/bin/bash
# You should source this file 'soruce ./env-vault-no-ssl.sh' so that 
# the enivonment variables set here, stick in the original shell
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export VAULT_ADDR=https://127.0.0.1:8200
# This verifies the Server Cert, so we use it's CA chain, not the clients
export VAULT_CACERT="$DIR/output/server-certs/ca_chain.pem"
export VAULT_CLIENT_CERT="$DIR/output/client-certs/client-cert.pem"
export VAULT_CLIENT_KEY="$DIR/output/client-certs/client-key.pem"