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
  display_name        = "${var.oke_name}-oke"
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
  compartment_id      = var.compartment_id
}

data "oci_file_storage_export_sets" "this" {
  display_name        = "${var.oke_name}-oke"
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
  compartment_id      = var.compartment_id
}

# namespace
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.kubes_namespace
  }
}

# @todo - make this an external secret and pull form service id
# resource "kubernetes_secret_v1" "image-pull" {
#   metadata {
#     name      = "image-pull"
#     namespace = var.kubes_namespace
#   }

#   type = data.kubernetes_secret_v1.kube-system-image-pull.type
#   data = data.kubernetes_secret_v1.kube-system-image-pull.data
# }

resource "kubernetes_role" "image-pull-reader" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  metadata {
    name      = "image-pull-reader"
    namespace = var.kubes_namespace
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["image-pull"]
    verbs          = ["get"]
  }
}

resource "kubernetes_role_binding" "image-pull-reader-default" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  metadata {
    name      = "image-pull-reader-default"
    namespace = var.kubes_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "image-pull-reader"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = var.kubes_namespace
  }
}
