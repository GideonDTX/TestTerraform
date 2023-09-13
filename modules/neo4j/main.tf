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

resource "kubernetes_secret_v1" "neo4j" {
  metadata {
    name      = "neo4j"
    namespace = var.kubernetes_namespace
  }

  type = "Opaque"

  data = {
    # helm chart requires the password value to start with 'neo4j/'
    # but it will trim that off to use as actual password
    NEO4J_AUTH     = "neo4j/${random_password.neo4j.result}"
    # so this is the actual password (and ItemService can mount this as env var)
    NEO4J_PASSWORD = random_password.neo4j.result
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
