resource "kubernetes_secret_v1" "certs" {
  metadata {
    name      = "certs"
    namespace = var.kubernetes_namespace
  }

  type = "Opaque"

  data = var.cert_files
}
