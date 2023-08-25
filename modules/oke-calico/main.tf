terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

# os namespace
data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

# kubeconf
data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id = var.cluster_id
}

# # this the correct provider when the VPN is in place
# provider "kubernetes" {
#   host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
#   cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
#   exec {
#     api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
#     command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
#     args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
#   }
# }

# this is the bastion configuration
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "${var.cluster_name}-bastion"
}

# # this the correct provider when the VPN is in place
# provider "kubectl" {
#   host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
#   cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
#   exec {
#     api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
#     command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
#     args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
#   }
# }

# this is the bastion configuration
provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "${var.cluster_name}-bastion"
}

data "kubectl_path_documents" "this" {
  pattern = "${path.module}/templates/calico-${var.calico_version}.yaml"
  vars = {
    region    = var.region
    namespace = data.oci_objectstorage_namespace.this.namespace
    version   = var.calico_version
  }
}

resource "kubectl_manifest" "this" {
  count     = length(data.kubectl_path_documents.this.documents)
  yaml_body = element(data.kubectl_path_documents.this.documents, count.index)
}