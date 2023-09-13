### resources

# namespace
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.kubernetes_namespace
  }
}

# service account
resource "kubernetes_service_account_v1" "this" {
  metadata {
    name      = "platform"
    namespace = var.kubernetes_namespace
  }
  automount_service_account_token = false
}

### datasources - needed for provider setup or other resources

# os namespace
data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

# lookup the availability domains
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

# lookup the mount target for this vcn/oke
data "oci_file_storage_mount_targets" "this" {
  display_name        = "${var.cluster_name}-oke"
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
  compartment_id      = var.compartment_id
}

data "oci_file_storage_export_sets" "this" {
  display_name        = "${var.cluster_name}-oke"
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
  compartment_id      = var.compartment_id
}
