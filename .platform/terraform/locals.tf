locals {
  has_domain = var.domain_name != ""

  static_fqdn = local.has_domain ? "${var.static_subdomain}.${var.domain_name}" : null
  app_fqdn    = local.has_domain ? "${var.app_subdomain}.${var.domain_name}" : null

  common_tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}
