locals {
  shell_labels = {
    "app.kubernetes.io/name"       = "shell"
    "app.kubernetes.io/instance"   = "shell-${var.kubernetes_namespace}"
    "app.kubernetes.io/component"  = "utility"
    "app.kubernetes.io/part-of"    = "ops"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

resource "kubernetes_deployment" "shell" {
  depends_on = [
    kubernetes_namespace_v1.this,
  ]

  metadata {
    name      = "shell"
    namespace = var.kubernetes_namespace
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
          image             = "ghcr.io/oracle/oci-cli:latest"
          name              = "shell"
          command = [
            "/bin/bash",
            "-c",
            "while true; do date; sleep 30; done"
          ]
          image_pull_policy = "Always"
        }
      }
    }
  }
}
