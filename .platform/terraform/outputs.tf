output "ecr_repository_url" {
  description = "Push images here from GitHub Actions."
  value       = aws_ecr_repository.app.repository_url
}

output "apprunner_service_url" {
  description = "Default AWS-provided URL for the App Runner service. Works before any custom domain is set up -- use this to verify the app before DNS cutover."
  value       = "https://${aws_apprunner_service.app.service_url}"
}

output "apprunner_service_arn" {
  value = aws_apprunner_service.app.arn
}

output "static_bucket_name" {
  value = aws_s3_bucket.static.bucket
}

output "cloudfront_distribution_id" {
  description = "Used for `aws cloudfront create-invalidation` after each static-asset sync."
  value       = aws_cloudfront_distribution.static.id
}

output "cloudfront_domain_name" {
  description = "Default CloudFront domain (*.cloudfront.net). Use this as STATIC_BASE_URL if you skip setting a custom static_subdomain."
  value       = aws_cloudfront_distribution.static.domain_name
}

output "github_actions_role_arn" {
  description = "Set as the `role-to-assume` input for aws-actions/configure-aws-credentials in the GitHub Actions workflow."
  value       = aws_iam_role.github_actions_deploy.arn
}

output "static_acm_certificate_validation_records" {
  description = "Add this CNAME at your DNS provider to validate the static-assets ACM cert. Empty until domain_name is set. See the two-step-apply note in s3_cloudfront.tf."
  value = local.has_domain ? [
    for o in aws_acm_certificate.static[0].domain_validation_options : {
      name  = o.resource_record_name
      type  = o.resource_record_type
      value = o.resource_record_value
    }
  ] : []
}

output "apprunner_custom_domain_validation_records" {
  description = "Add these records at your DNS provider to activate the App Runner custom domain's managed TLS cert. Empty until domain_name is set."
  value       = local.has_domain ? aws_apprunner_custom_domain_association.app[0].certificate_validation_records : []
}

output "apprunner_custom_domain_dns_target" {
  description = "CNAME target: point app_subdomain.<domain_name> at this. Empty until domain_name is set."
  value       = local.has_domain ? aws_apprunner_custom_domain_association.app[0].dns_target : null
}
