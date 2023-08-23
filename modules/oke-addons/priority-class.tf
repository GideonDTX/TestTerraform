# mostly taken from here: https://medium.com/pareture/a-simple-kubernetes-priority-class-model-e5db6df12dbe
resource "kubernetes_priority_class_v1" "agent" {
  metadata {
    name = "agent"
  }

  description = "for non-system agents on each node (e.g. logging)"
  value       = 50000
}

resource "kubernetes_priority_class_v1" "platform" {
  metadata {
    name = "platform"
  }

  description = "for the core platform"
  value       = 40000
}

resource "kubernetes_priority_class_v1" "application" {
  metadata {
    name = "application"
  }

  description = "for the applications built on platform"
  value       = 30000
}

# left gap for 20000 if needed

resource "kubernetes_priority_class_v1" "default" {
  metadata {
    name = "default"
  }

  description    = "default priority for pods with no policy defined"
  value          = 10000
  global_default = true
}
