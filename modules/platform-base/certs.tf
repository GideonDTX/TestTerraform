# resource "kubernetes_secret_v1" "certs" {
#   metadata {
#     name      = "certs"
#     namespace = var.env_name
#   }

#   type = "Opaque"

#   data = {
#     "dtxnonprodmongodb1.crt" = <<-EOT
#     # insert public cert here
#     EOT
#   }
# }
