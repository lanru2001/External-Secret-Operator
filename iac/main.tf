######################################################################################
#1. Install External Secret Operator using Helm Chart
######################################################################################

resource "helm_release" "external_secret_operator" {
  name             = "external-secrets"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  cleanup_on_fail  = true
  force_update     = true
  wait_for_jobs    = true
  atomic           = true
  timeout          = "600"

  # Reference your Helm values file
  values = [
    file("${path.module}/dev-values.yaml")
  ]
  
}
