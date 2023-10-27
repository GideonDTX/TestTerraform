locals {
  version   = "1.0.48"

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
