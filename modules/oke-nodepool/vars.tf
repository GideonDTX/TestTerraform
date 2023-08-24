variable "name" {
  description = "The name of the nodepool"
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version"
  type        = string
}

variable "compartment_id" {
  description = "The compartment id for placing resources"
  type        = string
}

variable "cluster_id" {
  description = "The id of the cluster"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

variable "min_size" {
  description = "Node minimum pool size"
  type        = number
}

variable "max_size" {
  description = "Node maximum pool size"
  type        = number
}

variable "autoscale" {
  description = "Autoscale the node pool?"
  type        = bool
}

variable "image_id" {
  description = "Node image id"
  type        = string
}

variable "shape" {
  description = "Node shape"
  type        = string
}

variable "cpu" {
  description = "Node OCPU size"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Node memory size"
  type        = number
  default     = 32
}

variable "disk" {
  description = "Node disk size"
  type        = number
  default     = 50
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "node_network_security_group_id" {
  description = "Node network security group id"
  type        = string
}

variable "node_subnet_id" {
  description = "Subnet id to place the nodes"
  type        = string
}

variable "node_labels" {
  description = "list of key/value pairs"
  type        = map(any)
  default     = {}
}
