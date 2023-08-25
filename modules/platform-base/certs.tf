# @todo - how to handle public certs? External Secret? Config Map?

# resource "kubernetes_secret_v1" "certs" {
#   metadata {
#     name      = "certs"
#     namespace = var.env_name
#   }

#   type = "Opaque"

#   data = {}
# }
