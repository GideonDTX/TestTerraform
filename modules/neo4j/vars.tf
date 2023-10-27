variable "compartment_id" {
  description = "The compartment id for placing resources"
  type        = string
}

variable "compartment_name" {
  description = "The compartment name for the zone"
  type        = string
}

variable "cluster_name" {
  description = "The name of the OKE cluster"
  type        = string
}

variable "helm_chart_version" {
  description = "Version of the helm chart"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Name of the Kubernetes namespace"
  type        = string
}

variable "container_repo_host" {
  description = "Container repository"
  type        = string
}
