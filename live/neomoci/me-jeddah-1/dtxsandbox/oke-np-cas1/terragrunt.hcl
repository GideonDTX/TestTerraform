locals {
  kubernetes_version = "v1.26.2"

  name = replace(basename(get_original_terragrunt_dir()), "oke-", "")

  min_size  = 3
  max_size  = 60
  autoscale = true

  shape = "VM.Standard3.Flex"

  # NOTE: We used to lookup the image from the name but Oracle removes old images
  #       so fast that it breaks the existing state when it can't look up the old
  #       image id. Now we just explicitly provide the id. You can find image ids
  #       and names with this command:
  #
  #       oci ce node-pool-options get --node-pool-option-id all
  #
  #       Full Example:
  #
  #       1. Only show OKE format (includes Kubernetes software ... MATCH VERSIONS!)
  #       2. Exclude GPU
  #       3. Exclude arm64 nodes
  #
  #       oci ce node-pool-options get --node-pool-option-id all | \
  #         jq -r '.data.sources[] | ."source-name" + " " + ."image-id"' | \
  #         grep -- "-OKE-" | \
  #         grep -v -- "-GPU-" | \
  #         grep -v -- "-aarch64-"
  #

  # id for Oracle-Linux-8.8-2023.08.31-0-OKE-1.26.2-645
  image_id  = "ocid1.image.oc1.me-jeddah-1.aaaaaaaaelsybrvo576gzkrid3fbbphrdnrbldcz5hx3fng5ncofs64mfdkq"

  # note cpu/memory values must be valid ratios (check documentation)
  cpu    = 4
  memory = 16
  disk   = 150

  labels = {
    "node.kubernetes.io/type" = "autoscale"
  }
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules//oke-nodepool"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "cluster" {
  config_path = "../oke-cluster"

  mock_outputs_allowed_terraform_commands = [
    "validate"
  ]
  mock_outputs = {
    id                      = "fake-id"
    name                    = "fake-name"
    compartment_id          = "fake-compartment-id"
    private_subnet_id       = "fake-private-subnet-id"
    network_security_groups = {
      workers = {
        id   = "ABC"
      }
    }
    ssh_public_key = "fake-ssh-key"
  }
}

dependencies {
  paths = [
    "../oke-cluster"
#    "../oke-calico",
  ]
}

inputs = {
  name               = local.name
  kubernetes_version = local.kubernetes_version
  compartment_id     = dependency.cluster.outputs.compartment_id

  min_size  = local.min_size
  max_size  = local.max_size
  autoscale = local.autoscale

  cluster_id   = dependency.cluster.outputs.id
  cluster_name = dependency.cluster.outputs.name

  image_id = local.image_id
  shape    = local.shape
  cpu      = local.cpu
  memory   = local.memory
  disk     = local.disk

  ssh_public_key  = dependency.cluster.outputs.ssh_public_key

  node_network_security_group_id = dependency.cluster.outputs.network_security_groups["workers"].id
  node_subnet_id                 = dependency.cluster.outputs.private_subnet_id
  node_labels                    = local.labels
}
