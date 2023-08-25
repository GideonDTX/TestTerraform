variable "region" {
  description = "region"
  type        = string
}

variable "compartment_id" {
  description = "The compartment id for placing resources"
  type        = string
}

variable "oke_name" {
  description = "The oke name"
  type        = string
}

variable "env_name" {
  description = "The environment name"
  type        = string
}

variable "kubes_namespace" {
  description = "The Kubernetes namespace of the application environment"
  type        = string
}

variable "approved_senders" {
  description = "Approved senders for the domain"
  type        = list(string)
}

variable "service_group" {
  description = "the service group to grant OCI API permissions to"
  type        = string
}