locals {
  defaults = {
    enable_kubernetes   = false,
    enable_kubectl      = false,
  }
  stack_yaml = try(yamldecode(file("${get_original_terragrunt_dir()}/stack.yaml")), {})

  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  stack_vars       = merge(local.defaults, local.stack_yaml)
}

# it feels like I could make this smarter
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  # we have to do these conditionals because of the multiple accounts
  contents = <<-EOF
  # main provider for oci
  provider "oci" {
    region              = "${local.region_vars.locals.region}"
    auth                = "SecurityToken"
    config_file_profile = "${get_env("OCI_CLI_PROFILE")}"
  }

  %{if local.stack_vars.enable_kubernetes}
  # this is needed because the generic kubernetes modules don't have explicit requirements
  terraform {
    required_providers {
      oci = {
        source  = "oracle/oci"
      }
      kubernetes = {
        source  = "hashicorp/kubernetes"
      }
      %{if local.stack_vars.enable_kubectl}
      kubectl = {
        source  = "gavinbunney/kubectl"
      }
      %{endif}
    }
  }

  data "oci_containerengine_clusters" "this" {
    name           = "${local.environment_vars.locals.environment}"
    compartment_id = "${local.environment_vars.locals.compartment_id}"
    state          = ["ACTIVE"]
  }

  # kubeconf
  data "oci_containerengine_cluster_kube_config" "this" {
    cluster_id = data.oci_containerengine_clusters.this.clusters[0].id
  }

  # kube provider
  provider "kubernetes" {
    host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
    cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
    exec {
      api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
      command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
      args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
    }
  }

  # helm provider
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

  %{if local.stack_vars.enable_kubectl}
  # kubectl
  provider "kubectl" {
    host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
    cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
    exec {
      api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
      command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
      args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
    }
  }
  %{endif}
  %{endif}
 EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket   = "dtx-terraform"
    key      = "${path_relative_to_include()}/terraform.tfstate"
    region   = "me-jeddah-1"
    endpoint = "https://axnfm4jb3i73.compat.objectstorage.me-jeddah-1.oraclecloud.com"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true

    # use these to avoid terragrunt warnings with OCI Object Storage Buckets
    skip_bucket_versioning             = true
    skip_bucket_ssencryption           = true
    skip_bucket_root_access            = true
    skip_bucket_enforced_tls           = true
    skip_bucket_public_access_blocking = true
  }
}
