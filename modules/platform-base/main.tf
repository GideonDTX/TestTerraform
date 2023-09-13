terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
    }

    helm = {
      source  = "hashicorp/helm"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

### resources

# namespace
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.kubernetes_namespace
  }
}

# service account
resource "kubernetes_service_account_v1" "this" {
  metadata {
    name      = "platform"
    namespace = var.kubernetes_namespace
  }
  automount_service_account_token = false
}

### datasources - needed for provider setup or other resources

# os namespace
data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

# lookup the availability domains
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

# lookup the mount target for this vcn/oke
data "oci_file_storage_mount_targets" "this" {
  display_name        = "${var.cluster_name}-oke"
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
  compartment_id      = var.compartment_id
}

data "oci_file_storage_export_sets" "this" {
  display_name        = "${var.cluster_name}-oke"
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
  compartment_id      = var.compartment_id
}

# oke
data "oci_containerengine_clusters" "this" {
  name           = var.cluster_name
  compartment_id = var.compartment_id
  state          = ["ACTIVE"]
}

# nodepools
data "oci_containerengine_node_pools" "this" {
  compartment_id = var.compartment_id
  cluster_id     = data.oci_containerengine_clusters.this.clusters[0].id
  state          = ["ACTIVE", "UPDATING"]
}

# kubeconf
data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id = data.oci_containerengine_clusters.this.clusters[0].id
}

provider "kubernetes" {
  host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
  cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
  exec {
    api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
    command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
    args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
  }
}

provider "helm" {
  kubernetes {
    host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
    cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
    exec {
      api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
      command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
      args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
    }
  }
}

provider "kubectl" {
  host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
  cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
  exec {
    api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
    command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
    args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
  }
}
