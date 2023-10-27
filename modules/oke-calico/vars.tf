variable "region" {
  description = "The region name"
  type        = string
}

variable "compartment_id" {
  description = "The compartment id for placing resources"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

variable "calico_version" {
  description = "The version of Calico"
  type        = string
}
