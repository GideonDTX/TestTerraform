variable "region" {
  description = "region"
  type        = string
}

variable "compartment_id" {
  description = "The compartment id for placing resources"
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

variable "oke_name" {
  description = "The name of the OKE cluster"
  type        = string
}

variable "workers_nsg_id" {
  description = "Node network security group id"
  type        = string
}

variable "data_subnet_id" {
  description = "Subnet id to place the NFS mount targets"
  type        = string
}
