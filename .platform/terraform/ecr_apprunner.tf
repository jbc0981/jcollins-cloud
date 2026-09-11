# Container image storage.
resource "aws_ecr_repository" "app" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# Lets the App Runner service pull the image from ECR.
resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.project_name}-apprunner-ecr-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "build.apprunner.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# Smallest/cheapest size: 1 instance always provisioned (billed for memory
# only while idle), scales up to 2 active instances under load.
resource "aws_apprunner_auto_scaling_configuration_version" "app" {
  auto_scaling_configuration_name = "${var.project_name}-min-cost"
  min_size                        = 1
  max_size                        = 2
  max_concurrency                 = 100

  tags = local.common_tags
}

resource "aws_apprunner_service" "app" {
  service_name = var.project_name

  source_configuration {
    # We push new images and deploy explicitly from GitHub Actions
    # (`aws apprunner start-deployment`), rather than having App Runner
    # auto-deploy on every ECR push.
    auto_deployments_enabled = false

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }

    image_repository {
      image_identifier      = "${aws_ecr_repository.app.repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "8080"
        runtime_environment_variables = local.has_domain ? {
          STATIC_BASE_URL = "https://${local.static_fqdn}"
        } : {}
      }
    }
  }

  instance_configuration {
    cpu    = var.apprunner_cpu
    memory = var.apprunner_memory
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.app.arn

  tags = local.common_tags
}

# App Runner manages its own TLS cert for the custom domain -- add the
# validation + DNS-target records from the outputs at your DNS provider once
# this is applied.
resource "aws_apprunner_custom_domain_association" "app" {
  count       = local.has_domain ? 1 : 0
  domain_name = local.app_fqdn
  service_arn = aws_apprunner_service.app.arn
}
