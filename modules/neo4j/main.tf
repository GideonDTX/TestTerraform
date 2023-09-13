resource "kubernetes_secret_v1" "neo4j" {
  metadata {
    name      = "neo4j"
    namespace = var.kubernetes_namespace
  }

  type = "Opaque"

  data = {
    # helm chart requires the password value to start with 'neo4j/'
    # but it will trim that off to use as actual password
    NEO4J_AUTH     = "neo4j/${random_password.neo4j.result}"
    # so this is the actual password (and ItemService can mount this as env var)
    NEO4J_PASSWORD = random_password.neo4j.result
  }
}

resource "random_password" "neo4j" {
  length           = 24
  special          = true
  override_special = "!@#*-_=+"
}

resource "helm_release" "neo4j1" {
  depends_on = [
    kubernetes_secret_v1.neo4j,
  ]

  name       = "neo4j1"
  namespace  = var.kubernetes_namespace
  repository = "https://helm.neo4j.com/neo4j/"
  chart      = "neo4j-standalone"
  version    = var.helm_chart_version

  values = [
    templatefile("templates/neo4j-values.yaml",{
      cluster_name         = "neo4j1",
      kubernetes_namespace = var.kubernetes_namespace,
      container_repo_host  = var.container_repo_host
      storage_class_name   = "oci-bv"
    })
  ]
}

resource "helm_release" "neo4j2" {
  depends_on = [
    kubernetes_secret_v1.neo4j,
  ]

  name       = "neo4j2"
  namespace  = var.kubernetes_namespace
  repository = "https://helm.neo4j.com/neo4j/"
  chart      = "neo4j-standalone"
  version    = var.helm_chart_version

  values = [
    templatefile("templates/neo4j-values.yaml",{
      cluster_name         = "neo4j2",
      kubernetes_namespace = var.kubernetes_namespace,
      container_repo_host  = var.container_repo_host
      storage_class_name   = "oci-bv"
    })
  ]
}
