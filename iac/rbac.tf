# Setup RBAC for External Secrets Service Account
resource "kubernetes_cluster_role_binding" "role_tokenreview_binding" {
  metadata {
    name = "role-tokenreview-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "external-secrets"
    namespace = "external-secrets"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
}
