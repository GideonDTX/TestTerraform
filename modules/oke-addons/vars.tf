variable "region" {
  description = "region"
  type        = string
}

variable "compartment_id" {
  description = "The compartment id for placing resources"
  type        = string
}

variable "shared_compartment_id" {
  description = "The compartment id for shared resources"
  type        = string
}

variable "compartment_name" {
  description = "The compartment name for the zone"
  type        = string
}

variable "vcn_id" {
  description = "The id of the VCN"
  type        = string
}

variable "cluster_id" {
  description = "The id of the OKE cluster"
  type        = string
}

variable "cluster_name" {
  description = "The name of the OKE cluster"
  type        = string
}

variable "workers_nsg_id" {
  description = "Node network security group id"
  type        = string
}

variable "loadbalancers_nsg_id" {
  description = "Load balancers security group id"
  type        = string
}

variable "data_subnet_id" {
  description = "Subnet id to place the NFS mount targets"
  type        = string
}

variable "vault_id" {
  description = "Vault id"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key id for the vault"
  type        = string
}

variable "service_id_secret" {
  description = "Secret data for service id"
  type        = string
}

variable "cluster_workers_group" {
  description = "Kubernetes cluster workers dynamic group"
  type        = string
}

variable "allowed_domain_zones" {
  description = "List of allowed domain zones for external-dns management"
  type        = list(string)
}
