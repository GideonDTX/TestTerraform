locals {
  providers = {
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}
