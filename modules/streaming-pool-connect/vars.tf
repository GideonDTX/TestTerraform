variable "name" {
  description = "The streaming service name"
  type        = string
}

variable "vcn_id" {
  description = "The Virtual Cloud Network id"
  type        = string
}

variable "compartment_id" {
  description = "The compartment id"
  type        = string
}

variable "compartment_name" {
  description = "The compartment name"
  type        = string
}

variable "cluster_name" {
  description = "The name of the OKE cluster"
  type        = string
}

variable "kubernetes_namespace" {
  description = "The name of the kubernetes namespace"
  type        = string
}

variable "subnet_id" {
  description = "The subnet id to place the Kafka endpoint"
  type        = string
}

variable "num_partitions" {
  description = "The default number of partitions"
  type        = number
  default     = 3
}

variable "log_retention_hours" {
  description = "Hours to retain log"
  type        = number
  default     = 168
}

variable "workers_nsg_id" {
  description = "Node network security group id"
  type        = string
}

variable "bastion_nsg_id" {
  description = "The bastion host's network"
  type        = string
}

variable "service_id_secret" {
  description = "secret data for service id"
  type        = string
}

variable "neom_vpn_cidr" {
  description = "NEOM older VPN CIDR"
  type        = string
}

variable "neom_cisco_vpn_cidr" {
  description = "NEOM newer VPN CIDR"
  type        = string
}
