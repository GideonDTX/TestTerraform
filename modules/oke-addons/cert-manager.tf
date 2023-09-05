resource "kubernetes_namespace_v1" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert-manager" {
  depends_on = [
    kubernetes_namespace_v1.cert-manager
  ]

  name       = "cert-manager"
  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.8.2"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "cert-manager-webhook-oci" {
  depends_on = [
    kubernetes_namespace_v1.cert-manager,
    helm_release.cert-manager
   ]

  name      = "cert-manager-webhook-oci"
  namespace = "cert-manager"
  chart     = "./charts/cert-manager-webhook-oci"
}

resource "kubectl_manifest" "clusterissuer-staging" {
  depends_on = [
    helm_release.cert-manager,
    helm_release.cert-manager-webhook-oci,
    kubectl_manifest.ocidns-cert-manager
  ]

  yaml_body = templatefile(
    "${path.module}/templates/clusterissuer-staging.yaml",
    {
      oci_profile_secret_name = "ocidns-cert-manager",
      dns_zone_compartment_id = var.shared_compartment_id
    }
  )
}

resource "kubectl_manifest" "clusterissuer-prod" {
  depends_on = [
    helm_release.cert-manager,
    helm_release.cert-manager-webhook-oci,
    kubectl_manifest.ocidns-cert-manager
  ]

  yaml_body = templatefile(
    "${path.module}/templates/clusterissuer-prod.yaml",
    {
      oci_profile_secret_name = "ocidns-cert-manager",
      dns_zone_compartment_id = var.shared_compartment_id
    }
  )
}

resource "kubectl_manifest" "ocidns-cert-manager" {
  depends_on = [
    kubernetes_namespace_v1.cert-manager
   ]
  yaml_body = <<-EOT
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: ocidns-cert-manager
      namespace: cert-manager
    spec:
      refreshInterval: "5m"
      secretStoreRef:
        kind: ClusterSecretStore
        name: oci-vault-${var.cluster_name}
      target:
        name: ocidns-cert-manager
        creationPolicy: Owner
        template:
          type: Opaque
          data:
            tenancy: "{{ .tenancy }}"
            user: "{{ .id }}"
            region: "${var.region}"
            fingerprint: "{{ .api_signing_key_fingerprint }}"
            privateKey: "{{ .api_signing_key_private }}"
            privateKeyPassphrase: ""
      dataFrom:
        - extract:
            key: ${var.service_id_secret}
  EOT
}

resource "kubernetes_role" "ocidns-cert-manager-reader" {
  depends_on = [
    kubernetes_namespace_v1.cert-manager
   ]

  metadata {
    name      = "ocidns-cert-manager-reader"
    namespace = "cert-manager"
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["ocidns-cert-manager"]
    verbs          = ["get"]
  }
}

resource "kubernetes_role_binding" "ocidns-cert-manager-reader" {
  depends_on = [
    kubernetes_namespace_v1.cert-manager
   ]

  metadata {
    name      = "ocidns-cert-manager-reader"
    namespace = "cert-manager"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "ocidns-cert-manager-reader"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cert-manager-webhook-oci"
    namespace = "cert-manager"
  }
}

# resource "helm_release" "cert-manager" {
#   name       = "cert-manager"
#   namespace  = "kube-system"
#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager"
#   version    = "v1.12.3"

#   set {
#     name  = "installCRDs"
#     value = "true"
#   }
# }

# resource "helm_release" "cert-manager-webhook-oci" {
#   depends_on = [
#     helm_release.cert-manager,
#   ]

#   name       = "cert-manager-webhook-oci"
#   namespace  = "kube-system"
#   repository = "https://dn13.gitlab.io/cert-manager-webhook-oci"
#   chart      = "cert-manager-webhook-oci"
#   version    = "1.2.1"
# }

# resource "kubectl_manifest" "clusterissuer-staging" {
#   depends_on = [
#     helm_release.cert-manager,
#     helm_release.cert-manager-webhook-oci,
#   ]

#   yaml_body = <<-EOT
#     apiVersion: cert-manager.io/v1
#     kind: ClusterIssuer
#     metadata:
#       name: letsencrypt-staging
#     spec:
#       acme:
#         server: https://acme-staging-v02.api.letsencrypt.org/directory
#         email: devops@invicara.com
#         privateKeySecretRef:
#           name: letsencrypt-staging
#         solvers:
#           - dns01:
#               webhook:
#                 groupName: acme.d-n.be
#                 solverName: oci
#                 config:
#                   ociProfileSecretName: "cert-manager"
#                   compartmentOCID: ${var.shared_compartment_id}

#   EOT
# }

# resource "kubectl_manifest" "clusterissuer-prod" {
#   depends_on = [
#     helm_release.cert-manager,
#     helm_release.cert-manager-webhook-oci,
#   ]

#   yaml_body = <<-EOT
#     apiVersion: cert-manager.io/v1
#     kind: ClusterIssuer
#     metadata:
#       name: letsencrypt-prod
#     spec:
#       acme:
#         server: https://acme-v02.api.letsencrypt.org/directory
#         email: devops@invicara.com
#         privateKeySecretRef:
#           name: letsencrypt-prod
#         solvers:
#           - dns01:
#               webhook:
#                 groupName: acme.d-n.be
#                 solverName: oci
#                 config:
#                   ociProfileSecretName: "cert-manager"
#                   compartmentOCID: ${var.shared_compartment_id}

#   EOT
# }

# resource "kubectl_manifest" "cert-manager" {
#   yaml_body = <<-EOT
#     apiVersion: external-secrets.io/v1beta1
#     kind: ExternalSecret
#     metadata:
#       name: cert-manager
#       namespace: kube-system
#     spec:
#       refreshInterval: "5m"
#       secretStoreRef:
#         kind: ClusterSecretStore
#         name: oci-vault-${var.cluster_name}
#       target:
#         name: cert-manager
#         creationPolicy: Owner
#         template:
#           type: Opaque
#           data:
#             tenancy: "{{ .tenancy }}"
#             user: "{{ .id }}"
#             region: "${var.region}"
#             fingerprint: "{{ .api_signing_key_fingerprint }}"
#             privateKey: "{{ .api_signing_key_private }}"
#             privateKeyPassphrase: ""
#       dataFrom:
#         - extract:
#             key: ${var.service_id_secret}
#   EOT
# }

# resource "kubernetes_cluster_role" "cert-mananager-webhook-oci" {
#   metadata {
#     name      = "cert-manager:allow-webhook-oci"
#   }

#   rule {
#     api_groups     = ["acme.d-n.be"]
#     resources      = ["oci"]
#     resource_names = ["*"]
#     verbs          = ["*"]
#   }
# }

# resource "kubernetes_cluster_role_binding" "cert-mananager-webhook-oci" {
#   metadata {
#     name      = "cert-manager:allow-webhook-oci"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cert-manager:allow-webhook-oci"
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = "cert-manager"
#     namespace = "kube-system"
#   }
# }
