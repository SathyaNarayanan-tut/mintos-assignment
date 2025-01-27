resource "kubernetes_namespace" "database" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_persistent_volume_claim" "sonarqube_pvc" {
  metadata {
    name      = "sonarqube-pvc"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.sonarqube_pvc_storage
      }
    }
  }
}

resource "helm_release" "postgresql" {
  name       = "postgres"
  namespace  = kubernetes_namespace.database.metadata[0].name
  repository = var.postgresql_chart_repository
  chart      = var.postgresql_chart_name

  set {
    name  = "auth.postgresPassword"
    value = var.postgresql_password
  }
}

resource "kubernetes_secret" "sonar_postgres_credentials" {
  metadata {
    name      = "sonar-postgres-credentials"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  data = {
    "postgres-user"     = base64encode(var.jdbc_username)
    "postgres-password" = base64encode(var.jdbc_password)
  }
}

resource "helm_release" "sonarqube" {
  name       = "sonarqube"
  namespace  = kubernetes_namespace.database.metadata[0].name
  repository = var.sonarqube_chart_repository
  chart      = var.sonarqube_chart_name

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.existingClaim"
    value = kubernetes_persistent_volume_claim.sonarqube_pvc.metadata[0].name
  }

  set {
    name  = "postgresql.enabled"
    value = "false"
  }

  set {
    name  = "jdbcDatabase"
    value = "sonarqube"
  }

  set {
    name  = "jdbcOverwrite.jdbcUsername"
    value = var.jdbc_username
  }

  set {
    name  = "jdbcOverwrite.enabled"
    value = "true"
  }

  set {
    name  = "jdbcOverwrite.jdbcPassword"
    value = var.jdbc_password
  }

  set {
    name  = "jdbcOverwrite.jdbcUrl"
    value = var.jdbc_url
  }

  set {
    name  = "monitoringPasscode"
    value = var.monitoring_passcode
  }

  set {
    name  = "edition"
    value = var.sonarqube_edition
  }

  set {
    name  = "resources.requests.memory"
    value = var.resources.memory_request
  }

  set {
    name  = "resources.requests.cpu"
    value = var.resources.cpu_request
  }

  set {
    name  = "resources.limits.memory"
    value = var.resources.memory_limit
  }

  set {
    name  = "resources.limits.cpu"
    value = var.resources.cpu_limit
  }

  set {
    name  = "sonarProperties.sonar.search.javaOpts"
    value = "-Xmx2g -Xms2g"
  }

  set {
    name  = "livenessProbe.initialDelaySeconds"
    value = var.probes.initial_delay_seconds
  }

  set {
    name  = "livenessProbe.timeoutSeconds"
    value = var.probes.timeout_seconds
  }

  set {
    name  = "livenessProbe.periodSeconds"
    value = var.probes.period_seconds
  }

  set {
    name  = "livenessProbe.failureThreshold"
    value = var.probes.failure_threshold
  }

  set {
    name  = "readinessProbe.initialDelaySeconds"
    value = var.probes.initial_delay_seconds
  }

  set {
    name  = "readinessProbe.timeoutSeconds"
    value = var.probes.timeout_seconds
  }

  set {
    name  = "readinessProbe.periodSeconds"
    value = var.probes.period_seconds
  }

  set {
    name  = "readinessProbe.failureThreshold"
    value = var.probes.failure_threshold
  }
}

resource "kubernetes_service" "sonarqube_service" {
  metadata {
    name      = "sonarqube-sonarqube"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  spec {
    selector = {
      app     = "sonarqube"
      release = "sonarqube"
    }

    ports {
      port        = 9000
      target_port = 9000
    }

    type = "NodePort"
  }
}

resource "kubernetes_ingress" "sonarqube_ingress" {
  metadata {
    name      = "sonarqube-ingress"
    namespace = kubernetes_namespace.database.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "false"
    }
  }

  spec {
    rules {
      host = var.ingress_hostname

      http {
        paths {
          path     = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.sonarqube_service.metadata[0].name
              port {
                number = 9000
              }
            }
          }
        }
      }
    }
  }
}
