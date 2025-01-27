variable "kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file for connecting to the Kubernetes cluster"
}

variable "namespace" {
  type        = string
  description = "The namespace for deploying resources"
}

variable "postgresql_chart_repository" {
  type        = string
  description = "Helm chart repository for PostgreSQL"
}

variable "postgresql_chart_name" {
  type        = string
  description = "Helm chart name for PostgreSQL"
}

variable "postgresql_password" {
  type        = string
  description = "Password for PostgreSQL database"
}

variable "sonarqube_chart_repository" {
  type        = string
  description = "Helm chart repository for SonarQube"
}

variable "sonarqube_chart_name" {
  type        = string
  description = "Helm chart name for SonarQube"
}

variable "sonarqube_edition" {
  type        = string
  description = "Edition of SonarQube (developer, community, etc.)"
}

variable "sonarqube_pvc_storage" {
  type        = string
  description = "Storage size for SonarQube PVC"
}

variable "jdbc_url" {
  type        = string
  description = "JDBC URL for connecting SonarQube to PostgreSQL"
}

variable "jdbc_username" {
  type        = string
  description = "JDBC username for PostgreSQL"
}

variable "jdbc_password" {
  type        = string
  description = "JDBC password for PostgreSQL"
}

variable "monitoring_passcode" {
  type        = string
  description = "Monitoring passcode for SonarQube"
}

variable "resources" {
  type = object({
    memory_request = string
    cpu_request    = string
    memory_limit   = string
    cpu_limit      = string
  })
  description = "Resource requests and limits for SonarQube"
}

variable "probes" {
  type = object({
    initial_delay_seconds = number
    timeout_seconds       = number
    period_seconds        = number
    failure_threshold     = number
  })
  description = "Liveness and readiness probe configurations for SonarQube"
}

variable "ingress_hostname" {
  type        = string
  description = "Hostname for SonarQube Ingress"
}
