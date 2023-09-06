# provider setup (after cluster is running)
data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id = oci_containerengine_cluster.this.id
}

# # this the correct provider when the VPN is in place
# provider "kubernetes" {
#   host                   = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.server
#   cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster.certificate-authority-data)
#   exec {
#     api_version = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.apiVersion
#     command     = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.command
#     args        = yamldecode(data.oci_containerengine_cluster_kube_config.this.content).users[0].user.exec.args
#   }
# }

# this is the bastion configuration
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "${var.name}-bastion"
}

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
