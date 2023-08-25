# create the graphicssvc filesystem
resource "oci_file_storage_file_system" "graphicssvc" {
  display_name        = "${var.env_name}-graphicssvc"
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
}

# the fss export
resource "oci_file_storage_export" "graphicssvc" {
  export_set_id  = data.oci_file_storage_export_sets.this.export_sets[0].id
  file_system_id = oci_file_storage_file_system.graphicssvc.id
  path           = "/${var.env_name}-graphicssvc"

  export_options {
    source                         = "0.0.0.0/0" # this is okay because we are protecting it via network source groups
    access                         = "READ_WRITE"
    identity_squash                = "NONE"
    require_privileged_source_port = false
  }
}

resource "kubernetes_persistent_volume" "graphicssvc" {
  metadata {
    name = "${var.env_name}-graphicssvc"
  }

  spec {
    storage_class_name = "oci-fss"

    capacity = {
      storage = "50Gi"
    }

    access_modes = [
      "ReadWriteMany"
    ]

    mount_options = [
      "nosuid"
    ]

    persistent_volume_source  {
      nfs {
        server    = "fss1.prv1.${var.oke_name}.oraclevcn.com"
        path      = "/${var.env_name}-graphicssvc"
        read_only = false
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "graphicssvc" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  metadata {
    name      = "graphicssvc"
    namespace = var.kubes_namespace
  }

  spec {
    storage_class_name = "oci-fss"

    resources {
      requests = {
        storage = "50Gi"
      }
    }

    access_modes = [
      "ReadWriteMany"
    ]

    volume_name = "${var.env_name}-graphicssvc"
  }
}
