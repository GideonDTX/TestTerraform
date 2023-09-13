# ad
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

# vcn
data "oci_core_vcn" "this" {
  vcn_id = var.vcn_id
}

# nodepools
data "oci_containerengine_node_pools" "this" {
  compartment_id = var.compartment_id
  cluster_id     = var.cluster_id
  state          = ["ACTIVE", "UPDATING"]
}
