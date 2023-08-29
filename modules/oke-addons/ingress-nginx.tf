resource "oci_core_public_ip" "ingress-nginx" {
  lifecycle {
    # do not accidentally destroy public ip of load balancer
    prevent_destroy = true

    # needed because of this bug: https://github.com/oracle/terraform-provider-oci/issues/1479
    ignore_changes = [
      private_ip_id
    ]
  }

  compartment_id = var.compartment_id
  display_name   = "${var.cluster_name}-ingress-nginx-loadbalancer-ip"
  lifetime       = "RESERVED"
}

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

  # set public ip
  set {
    name = "controller.service.loadBalancerIP"
    value = oci_core_public_ip.ingress-nginx.ip_address
  }

  # OCI specific - set nsg ourselves

  set {
    # NOTE: if you switch to network load balancers, use this annontation:
    # name  = "controller.service.annotations.oci-network-load-balancer\\.oraclecloud\\.com/security-list-management-mode"
    # this is for application load balancers
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-security-list-management-mode"
    value = "None"
  }

  # OCI specific - set nsg
  set {
    # NOTE: if you switch to network load balancers, use this annontation:
    # name  = "controller.service.annotations.oci-network-load-balancer\\.oraclecloud\\.com/oci-network-security-groups"
    # this is for application load balancers
    name  = "controller.service.annotations.oci\\.oraclecloud\\.com/oci-network-security-groups"
    value = var.loadbalancers_nsg_id
  }

  # From here: https://kubernetes.github.io/ingress-nginx/deploy/
  #
  #   "If the load balancers of your cloud provider do active healthchecks on their backends (most do),
  #    you can change the externalTrafficPolicy of the ingress controller Service to Local (instead of
  #    the default Cluster) to save an extra hop in some cases."
  #
  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  # From here: https://kubernetes.github.io/ingress-nginx/
  #
  #   "If a single instance of the Ingress-NGINX controller is the sole Ingress controller running in
  #    your cluster, you should add the annotation "ingressclass.kubernetes.io/is-default-class" in your
  #    IngressClass, so any new Ingress objects will have this one as default IngressClass.
  #
  #    When using Helm, you can enable this annotation by setting `controller.ingressClassResource.default: true`
  #    in your Helm chart installation's values file.
  #
  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
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
