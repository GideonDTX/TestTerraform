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
  }
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
# provider "helm" {
#   kubernetes {
#     host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
#     cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
#     exec {
#       api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
#       command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
#       args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
#     }
#   }
# }

# this is the bastion configuration
provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "${var.cluster_name}-bastion"
  }
}

resource "kubernetes_secret_v1" "neo4j" {
  metadata {
    name      = "neo4j"
    namespace = var.kubernetes_namespace
  }

  type = "Opaque"

  data = {
    "NEO4J_DATA": random_password.neo4j.result
  }
}

resource "random_password" "neo4j" {
  length           = 24
  special          = true
  override_special = "!@#*-_=+"
}

resource "helm_release" "neo4j1" {
  depends_on = [
    kubernetes_secret_v1.neo4j,
  ]

  name       = "neo4j1"
  namespace  = var.kubernetes_namespace
  repository = "https://helm.neo4j.com/neo4j/"
  chart      = "neo4j-standalone"
  version    = var.helm_chart_version

  values = [
    templatefile("templates/neo4j-values.yaml",{
      cluster_name         = "neo4j1",
      kubernetes_namespace = var.kubernetes_namespace,
      container_repo_host  = var.container_repo_host
      storage_class_name   = "oci-bv"
    })
  ]
}

resource "helm_release" "neo4j2" {
  depends_on = [
    kubernetes_secret_v1.neo4j,
  ]

  name       = "neo4j2"
  namespace  = var.kubernetes_namespace
  repository = "https://helm.neo4j.com/neo4j/"
  chart      = "neo4j-standalone"
  version    = var.helm_chart_version

  values = [
    templatefile("templates/neo4j-values.yaml",{
      cluster_name         = "neo4j2",
      kubernetes_namespace = var.kubernetes_namespace,
      container_repo_host  = var.container_repo_host
      storage_class_name   = "oci-bv"
    })
  ]
}
