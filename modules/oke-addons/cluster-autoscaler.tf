locals {
  cluster_autoscaler_version = "1.26.2-7"

  # this needs the spaces because we are interpolating the variable in the yaml file below
  nodepools = [
    for obj in data.oci_containerengine_node_pools.this.node_pools :
      "            - --nodes=${obj.freeform_tags.autoscale_min_size}:${obj.freeform_tags.autoscale_max_size}:${obj.id}" if obj.freeform_tags.autoscale_enable == "true"
  ]
}

resource "oci_identity_policy" "autoscaler-manage-node-pools" {
  name           = "${var.oke_name}-autoscaler-manage-node-pools"
  description    = "allow autoscaler instances to manage node pools"
  compartment_id = var.compartment_id

  statements = [
    "Allow dynamic-group ${var.oke_name}-oke-workers to manage cluster-node-pools in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${var.oke_name}-oke-workers to manage instance-family in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${var.oke_name}-oke-workers to use subnets in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${var.oke_name}-oke-workers to read virtual-network-family in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${var.oke_name}-oke-workers to use vnics in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${var.oke_name}-oke-workers to inspect compartments in compartment id ${var.compartment_id}",
  ]
}

data "kubectl_path_documents" "manifests" {
  pattern = "${path.module}/templates/cluster-autoscaler.yaml"
  vars = {
    nodepools_list = join("\n", local.nodepools)
    image_tag      = local.cluster_autoscaler_version
  }
}

resource "kubectl_manifest" "this" {
  count     = length(data.kubectl_path_documents.manifests.documents)
  yaml_body = element(data.kubectl_path_documents.manifests.documents, count.index)
}
