variable "aws_region" {
  description = "AWS region for ECR, App Runner, and the static-assets S3 bucket. CloudFront itself is global; its ACM certificate always provisions in us-east-1 regardless of this value."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix/tag AWS resources for this project."
  type        = string
  default     = "jcollins-cloud"
}

variable "domain_name" {
  description = "Root domain the site lives under, e.g. \"justincollins.dev\". Leave empty to stand everything up on the default App Runner / CloudFront URLs first and add the custom domain later."
  type        = string
  default     = ""
}

variable "app_subdomain" {
  description = "Subdomain the Flask app is served on, e.g. \"www\" for www.<domain_name>. Ignored when domain_name is empty."
  type        = string
  default     = "www"
}

variable "static_subdomain" {
  description = "Subdomain static assets are served on via CloudFront, e.g. \"static\" for static.<domain_name>. Ignored when domain_name is empty."
  type        = string
  default     = "static"
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the deploy role via OIDC, in \"owner/repo\" form."
  type        = string
  default     = "jbc0981/jcollins-cloud"
}

variable "github_deploy_branch" {
  description = "Branch allowed to assume the deploy role -- only pushes/merges to this branch can deploy."
  type        = string
  default     = "main"
}

variable "apprunner_cpu" {
  description = "App Runner vCPU allocation in App Runner units (1024 = 1 vCPU). 256 is the smallest/cheapest size."
  type        = string
  default     = "256"
}

variable "apprunner_memory" {
  description = "App Runner memory allocation in MB. 512 is the smallest/cheapest size."
  type        = string
  default     = "512"
}
