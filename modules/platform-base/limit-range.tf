resource "kubernetes_limit_range_v1" "this" {
  metadata {
    name      = "default"
    namespace = var.kubernetes_namespace
  }
  spec {
    limit {
      type = "Container"
      default_request = {
        cpu               = "100m"
        memory            = "32Mi"
        ephemeral-storage = "64Mi"
      }
    }
  }
}
