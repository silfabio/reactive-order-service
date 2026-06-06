variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "kafka_version" {
  type    = string
  default = "3.6.0"
}

variable "number_of_broker_nodes" {
  type    = number
  default = 2
}

variable "instance_type" {
  type    = string
  default = "kafka.t3.small"
}

variable "volume_size" {
  type    = number
  default = 20
}

variable "cluster_create_timeout" {
  description = "Max time to wait for the MSK cluster to become ACTIVE. Use a short value locally (Floci is near-instant); keep the default 60m for real AWS."
  type        = string
  default     = "60m"
}
