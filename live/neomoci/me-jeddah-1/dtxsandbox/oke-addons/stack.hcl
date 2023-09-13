locals {
  providers = {
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }

    helm = {
      source  = "hashicorp/helm"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
    }

    tls = {
      source  = "hashicorp/tls"
    }
  }
}
