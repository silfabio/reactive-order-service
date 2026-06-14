variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_name_root" {
  description = "Common name for the root CA"
  type        = string
}

variable "common_name_intermediate" {
  description = "Common name for the intermediate CA"
  type        = string
}

variable "client_common_name" {
  description = "Common name issued on Order Service client certificates and allowed by the order-service-client PKI role"
  type        = string
  default     = "order-service.client"
}

variable "pki_root_ttl" {
  description = "TTL of the root CA certificate"
  type        = string
}

variable "pki_intermediate_ttl" {
  description = "TTL of the intermediate CA certificate"
  type        = string
}

variable "pki_cert_ttl" {
  description = "TTL of short-lived client certificates issued to the Order Service"
  type        = string
}

variable "postgres_server_cert_ttl" {
  description = "TTL of the Postgres server certificate"
  type        = string
}

variable "postgres_server_dns_names" {
  description = "DNS names the Postgres server certificate is valid for. The first entry is used as the certificate's common name."
  type        = list(string)
}

variable "postgres_server_ip_sans" {
  description = "IP SANs for the Postgres server certificate"
  type        = list(string)
  default     = []
}

variable "certs_output_dir" {
  description = "Local directory the Postgres server cert/key and CA chain are written to (gitignored)"
  type        = string
}
