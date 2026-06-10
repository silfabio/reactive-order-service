#!/bin/sh
set -eu

# Install Vault (Amazon Linux 2023 / RHEL-family)
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
dnf install -y vault-${vault_version}-1

mkdir -p /opt/vault/data
chown -R vault:vault /opt/vault/data

PRIVATE_IP="$(hostname -i)"

cat > /etc/vault.d/vault.hcl <<EOF
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "$(hostname)"

  retry_join {
    auto_join             = "provider=aws region=${aws_region} tag_key=${cluster_tag_key} tag_value=${cluster_tag_value}"
    auto_join_scheme      = "http"
  }
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  # TODO: enable TLS once the Vault PKI follow-up issues per-node certificates
  tls_disable = true
}

seal "awskms" {
  region     = "${aws_region}"
  kms_key_id = "${kms_key_id}"
}

api_addr     = "http://$${PRIVATE_IP}:8200"
cluster_addr = "http://$${PRIVATE_IP}:8201"
ui           = true
EOF

systemctl enable vault
systemctl start vault
