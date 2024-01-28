resource "kubernetes_secret_v1" "image-pull" {
  metadata {
    name      = "image-pull"
    namespace = "kube-system"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.region_name}.ocir.io" = {
          username = local.service_id.ocir_username
          password = local.service_id.auth_token
          email = local.service_id.email
          auth = base64encode("${local.service_id.ocir_username}:${local.service_id.auth_token}")
        }
      }
    })
  }
}

