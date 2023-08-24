locals {
  kubernetes_version = "v1.26.2"
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//oke-cluster"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "vcn" {
  config_path = "../vcn"

  mock_outputs_allowed_terraform_commands = [
    "validate"
  ]
  mock_outputs = {
    id             = "fake-id"
    name           = "fake-name"
    compartment_id = "fake-compartment-id"
    subnets        = {
      subnet1 = {
        id   = "ABC"
        tier = "app"
        type = "private"
      }
    }
    bastion_nsg_id = "XXX"
  }
}

dependencies {
  paths = [
    "../vcn"
  ]
}

inputs = {
  # cluster is named the same as the VCN
  name               = dependency.vcn.outputs.name
  vcn_id             = dependency.vcn.outputs.id
  compartment_id     = dependency.vcn.outputs.compartment_id
  public_subnet_id   = dependency.vcn.outputs.subnets["public1"].id
  private_subnet_id  = dependency.vcn.outputs.subnets["application1"].id
  kubernetes_version = local.kubernetes_version
  bastion_nsg_id     = dependency.vcn.outputs.bastion_nsg_id
}
