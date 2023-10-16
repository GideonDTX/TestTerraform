locals {}

# ad
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

# cloud-init for workers
data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "worker.sh"
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/worker.sh", {})
  }
}

# nodepool
resource "oci_containerengine_node_pool" "this" {
  lifecycle {
    ignore_changes = [
      node_config_details["size"]
    ]
  }

  name           = "${var.cluster_name}-${var.name}"
  compartment_id = var.compartment_id
  cluster_id     = var.cluster_id

  kubernetes_version = var.kubernetes_version

  node_metadata = {
    user_data = data.cloudinit_config.this.rendered
  }

  node_config_details {
    size = var.min_size

    nsg_ids                             = [var.node_network_security_group_id]

    node_pool_pod_network_option_details {
      cni_type = "FLANNEL_OVERLAY"
    }

    dynamic "placement_configs" {
      for_each = [
        for obj in data.oci_identity_availability_domains.this.availability_domains :
          obj.name
      ]

      content {
        availability_domain = placement_configs.value
        subnet_id           = var.node_subnet_id
      }
    }
  }

  node_source_details {
    image_id                = var.image_id
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = var.disk
  }

  node_shape = var.shape
  node_shape_config {
    ocpus         = var.cpu
    memory_in_gbs = var.memory
  }

  ssh_public_key = var.ssh_public_key

  dynamic "initial_node_labels" {
    for_each = var.node_labels

    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }

  freeform_tags = {
    "autoscale_enable"   = var.autoscale
    "autoscale_min_size" = var.min_size
    "autoscale_max_size" = var.max_size
  }
}
