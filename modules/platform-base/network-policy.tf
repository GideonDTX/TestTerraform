# resource "kubernetes_network_policy_v1" "this" {
#   depends_on = [
#     kubernetes_namespace_v1.this
#   ]

#   metadata {
#     name      = "allow-intra-namespace"
#     namespace = var.kubes_namespace
#   }

#   spec {
#     pod_selector {
#       match_labels = {}
#     }

#     ingress {
#       from {
#         pod_selector {
#           match_labels = {}
#         }
#       }
#     }

#     policy_types = [
#       "Ingress"
#     ]
#   }
# }
