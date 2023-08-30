locals {
  external_dns_version = "0.13.5"
  external_dns_labels = {
    "app.kubernetes.io/name"       = "external-dns"
    "app.kubernetes.io/instance"   = "external-dns"
    "app.kubernetes.io/component"  = "utility"
    "app.kubernetes.io/part-of"    = "external-dns"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

data "oci_dns_zones" "this" {
  for_each = toset(var.allowed_domain_zones)

  compartment_id = var.shared_compartment_id
  name           = each.key
}

# From https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/oracle.md
resource "kubernetes_service_account_v1" "external-dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
  }
  automount_service_account_token = false
}

resource "kubernetes_cluster_role_v1" "external-dns" {
  metadata {
    name = "external-dns"
  }

  rule {
    api_groups     = [""]
    resources      = ["services", "endpoints", "pods"]
    verbs          = ["get", "watch", "list"]
  }

  rule {
    api_groups     = ["extensions", "networking.k8s.io"]
    resources      = ["ingresses"]
    verbs          = ["get", "watch", "list"]
  }

  rule {
    api_groups     = [""]
    resources      = ["nodes"]
    verbs          = ["list"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "external-dns" {
  metadata {
    name      = "external-dns-viewer"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "external-dns"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "external-dns"
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment_v1" "external-dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
  }

  spec {
    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = local.external_dns_labels
    }

    template {
      metadata {
        labels = local.external_dns_labels
      }

      spec {
        container {
          name  = "external-dns"
          image = "registry.k8s.io/external-dns/external-dns:v${local.external_dns_version}"
          args  = concat(
            [
              "--source=service",
              "--source=ingress",
              "--provider=oci",
              "--oci-auth-instance-principal",
              "--oci-compartment-ocid=${var.shared_compartment_id}",
              "--policy=upsert-only",
              "--interval=90s",
              "--txt-owner-id=${var.cluster_name}-ext-dns",
            ],
            [
              for zone in var.allowed_domain_zones:
                "--zone-id-filter=${data.oci_dns_zones.this[zone].zones[0].id}"
            ]
          )
        }

        service_account_name = "external-dns"
      }
    }
  }
}
