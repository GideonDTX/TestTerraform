locals {
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  stack_vars       = try(read_terragrunt_config("${get_original_terragrunt_dir()}/stack.hcl"), {})

  oci_auth             = "${can(get_env("OCI_CLI_AUTH")) ? get_env("OCI_CLI_AUTH") : "api_key" }"
  oci_auth_pascal_case = "${can(get_env("OCI_CLI_AUTH")) ? join("", [for word in split("_", get_env("OCI_CLI_AUTH")): title(word)]) : "APIKey" }"
  oci_profile          = "${can(get_env("OCI_CLI_PROFILE")) ? get_env("OCI_CLI_PROFILE") : "DEFAULT" }"

  default_providers = {
    oci = {
      source = "oracle/oci"
    }
  }
  stack_providers = try(local.stack_vars.locals.providers, {})
  providers = merge(local.default_providers, local.stack_providers)
}

# it feels like I could make this smarter
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  # we have to do these conditionals because of the multiple accounts
  contents = <<EOF
# dyanmically set providers
terraform {
  required_providers {
    %{~ for name, obj in local.providers ~}
    ${name} = {
    %{~ for key in keys(obj) ~}
      ${key} = "${obj[key]}"
    %{~ endfor ~}
    }
    %{~ endfor ~}
  }
}

# main provider for oci
provider "oci" {
  region              = "${local.region_vars.locals.region}"
  auth                = "${local.oci_auth_pascal_case}"
  config_file_profile = "${local.oci_profile}"
}

%{~ if contains(keys(local.providers), "kubernetes") || contains(keys(local.providers), "helm") || contains(keys(local.providers), "kubectl") ~}
data "oci_containerengine_clusters" "this" {
  name           = "${local.environment_vars.locals.cluster_name}"
  compartment_id = "${local.environment_vars.locals.compartment_id}"
  state          = ["ACTIVE"]
}

# get kubeconf for kubernetes, helm, and kubectl
data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id =  data.oci_containerengine_clusters.this.clusters[0].id
}

%{~ endif ~}
%{~ if contains(keys(local.providers), "kubernetes") ~}
# configure kubernetes
provider "kubernetes" {
  host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
  cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
  exec {
    api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
    command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
    args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
    env         = {
      OCI_CLI_AUTH    = "${local.oci_auth}"
      OCI_CLI_PROFILE = "${local.oci_profile}"
    }
  }
}

%{~ endif ~}
%{~ if contains(keys(local.providers), "helm") ~}
# configure helm
provider "helm" {
  kubernetes {
    host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
    cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
    exec {
      api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
      command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
      args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
      env         = {
        OCI_CLI_AUTH    = "${local.oci_auth}"
        OCI_CLI_PROFILE = "${local.oci_profile}"
      }
    }
  }
}

%{~ endif ~}
%{~ if contains(keys(local.providers), "kubectl") ~}
# configure kubectl
provider "kubectl" {
  host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
  cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
  exec {
    api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
    command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
    args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
    env         = {
      OCI_CLI_AUTH    = "${local.oci_auth}"
      OCI_CLI_PROFILE = "${local.oci_profile}"
    }
  }
}

%{~ endif ~}
EOF
}

