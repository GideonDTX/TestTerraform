locals {
  shell_labels = {
    "app.kubernetes.io/name"       = "shell"
    "app.kubernetes.io/instance"   = "shell-${var.env_name}"
    "app.kubernetes.io/component"  = "utility"
    "app.kubernetes.io/part-of"    = "ops"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

resource "kubernetes_service_account_v1" "shell" {
  depends_on = [
    kubernetes_namespace_v1.this
  ]

  metadata {
    name      = "shell"
    namespace = var.kubes_namespace
  }

  automount_service_account_token = false
}

resource "kubernetes_deployment" "shell" {
  lifecycle {
    replace_triggered_by = [
      kubernetes_secret_v1.image-pull
    ]
  }

  depends_on = [
    kubernetes_namespace_v1.this,
    kubernetes_secret_v1.image-pull,
    kubernetes_role_binding.image-pull-reader-default,
    kubernetes_service_account_v1.shell,
  ]

  metadata {
    name      = "shell"
    namespace = var.kubes_namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.shell_labels
    }

    template {
      metadata {
        name   = "shell"
        labels = local.shell_labels
      }

      spec {
        container {
          image             = "${var.region}.ocir.io/${data.oci_objectstorage_namespace.this.namespace}/dtx/library/ubuntu:jammy"
          name              = "shell"
          command = [
            "/bin/bash",
            "-c",
            "while true; do date; sleep 30; done"
          ]
          image_pull_policy = "Always"
        }

        image_pull_secrets {
          name = "image-pull"
        }

        service_account_name = "shell"
      }
    }
  }
}
