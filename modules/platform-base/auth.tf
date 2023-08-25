resource "kubernetes_service_account_v1" "platform" {
  metadata {
    name      = "platform"
    namespace = var.env_name
  }
  automount_service_account_token = false
}
