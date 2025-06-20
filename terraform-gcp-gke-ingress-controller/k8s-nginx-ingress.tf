resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name        = "nginx-ingress"
    annotations = {}
    labels      = {}
  }
}

resource "helm_release" "nginx_ingress" {
  name = "nginx-ingress-controller"

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "nginx-ingress-controller"

  namespace = kubernetes_namespace.nginx_ingress.metadata[0].name

  set {
    name  = "service.type"
    value = "ClusterIP"
  }
}
