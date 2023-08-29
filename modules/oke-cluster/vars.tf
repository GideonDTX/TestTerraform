variable "name" {
  description = "The name of the Cluster"
  type        = string
}

variable "region_name" {
  description = "The region name for OCIR"
  type        = string
}

variable "vcn_id" {
  description = "The id of the vcn"
  type        = string
}

variable "compartment_id" {
  description = "The compartment id for placing resources"
  type        = string
}

variable "public_subnet_id" {
  description = "public subnet ids (for load balancers)"
  type        = string
}

variable "private_subnet_id" {
  description = "private subnet ids (for nodes and pods)"
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version"
  type        = string
}

variable "bastion_nsg_id" {
  description = "The bastion host's network "
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
