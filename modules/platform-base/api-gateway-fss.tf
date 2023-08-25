# create the api-gateway filesystem
resource "oci_file_storage_file_system" "api-gateway" {
  display_name        = "${var.env_name}-api-gateway"
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
}

# the fss export
resource "oci_file_storage_export" "api-gateway" {
  export_set_id  = data.oci_file_storage_export_sets.this.export_sets[0].id
  file_system_id = oci_file_storage_file_system.api-gateway.id
  path           = "/${var.env_name}-api-gateway"

  export_options {
    source                         = "0.0.0.0/0" # this is okay because we are protecting it via network source groups
    access                         = "READ_WRITE"
    identity_squash                = "NONE"
    require_privileged_source_port = false
  }
}

resource "kubernetes_persistent_volume" "api-gateway" {
  metadata {
    name = "${var.env_name}-api-gateway"
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
        server    = "fss1.data1.${var.oke_name}.oraclevcn.com"
        path      = "/${var.env_name}-api-gateway"
        read_only = false
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "api-gateway" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  metadata {
    name      = "api-gateway"
    namespace = var.kubes_namespace
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

    volume_name = "${var.env_name}-api-gateway"
  }
}
