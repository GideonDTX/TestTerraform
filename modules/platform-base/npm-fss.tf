# create the npm filesystem
resource "oci_file_storage_file_system" "npm" {
  display_name        = "${var.kubernetes_namespace}-npm"
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
}

# the fss export
resource "oci_file_storage_export" "npm" {
  export_set_id  = data.oci_file_storage_export_sets.this.export_sets[0].id
  file_system_id = oci_file_storage_file_system.npm.id
  path           = "/${var.kubernetes_namespace}-npm"

  export_options {
    source                         = "0.0.0.0/0" # this is okay because we are protecting it via network source groups
    access                         = "READ_WRITE"
    identity_squash                = "NONE"
    require_privileged_source_port = false
  }
}

resource "kubernetes_persistent_volume" "npm" {
  metadata {
    name = "${var.kubernetes_namespace}-npm"
  }

  spec {
    storage_class_name = "oci-fss"

    capacity = {
      storage = "1Gi"
    }

    access_modes = [
      "ReadWriteMany"
    ]

    mount_options = [
      "nosuid"
    ]

    persistent_volume_source  {
      nfs {
        server    = "fss1.data1.${var.cluster_name}.oraclevcn.com"
        path      = "/${var.kubernetes_namespace}-npm"
        read_only = false
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "npm" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  metadata {
    name      = "npm"
    namespace = var.kubernetes_namespace
  }

  spec {
    storage_class_name = "oci-fss"

    resources {
      requests = {
        storage = "1Gi"
      }
    }

    access_modes = [
      "ReadWriteMany"
    ]

    volume_name = "${var.kubernetes_namespace}-npm"
  }
}
