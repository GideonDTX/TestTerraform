resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.7.1"

  # high availability
  set {
    name  = "controller.replicaCount"
    value = 2
  }

  set {
    name  = "controller.autoscaling.minReplicas"
    value = "2"
  }

  # force ssl
  set {
    name  = "controller.config.ssl-redirect"
    value = "true"
  }

  # enable gzip
  set {
    name  = "controller.config.use-gzip"
    value = "true"
  }

  set {
    name  = "controller.config.gzip-level"
    value = "6"
  }

  # proxy buffering (needed this because PlatformIAM was sending back big responses)
  set {
    name  = "controller.config.proxy-buffer-size"
    value = "16k"
  }

  # this is needed for things like itemsc (leave it for everything)
  set {
    name  = "controller.config.client-body-timeout"
    value = "180"
  }

  # this was needed by passportsvc (not sure if it still is)
  set {
    name  = "controller.config.enable-underscores-in-headers"
    value = "true"
  }

  # this should probably only be for graphics/websockets
  set {
    name  = "controller.config.proxy-read-timeout"
    value = "3600"
  }

  set {
    name  = "controller.config.proxy-send-timeout"
    value = "180"
  }

  # this is probably only needed for filesvc
  set {
    name  = "controller.config.proxy-request-buffering"
    value = "off"
  }

  set {
    name  = "controller.config.proxy-body-size"
    value = "0"
  }

  # needed because of important message here: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#keep-alive
  # `Setting keep-alive: '0' will most likely break concurrent http/2 requests due to changes introduced with nginx 1.19.7`
  set {
    name  = "controller.config.keep-alive"
    value = "1"
  }

  set {
    name  = "controller.config.keep-alive-requests"
    value = "2000"
  }
}
