locals {
  providers = {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }

    tls = {
      source  = "hashicorp/tls"
    }

    # need this for image-pull
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
  }
}
