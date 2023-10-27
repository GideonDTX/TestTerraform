variable "region" {
  description = "region"
  type        = string
}

variable "compartment_id" {
  description = "The compartment id"
  type        = string
}

variable "shared_compartment_id" {
  description = "The compartment id for placing resources"
  type        = string
}

variable "compartment_name" {
  description = "The compartment name"
  type        = string
}

variable "vcn_id" {
  description = "The id of the VCN network"
  type        = string
}

variable "cluster_name" {
  description = "The name of the OKE cluster"
  type        = string
}

variable "kubernetes_namespace" {
  description = "The Kubernetes namespace of the application environment"
  type        = string
}

variable "service_id_secret" {
  description = "Secret data for service id"
  type        = string
}

variable "approved_senders" {
  description = "Approved senders for the domain"
  type        = list(string)
}

variable "dns_names" {
  description = "DNS names to be used on platform"
  type        = map(string)
}

variable "cert_files" {
  description = "Map of cert files"
  type        = map(string)
}
