locals {
  version   = "master"

  providers = {
    aws = {
      source  = "hashicorp/aws"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}
