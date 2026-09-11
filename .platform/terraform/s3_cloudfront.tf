# Static assets (images, css, the resume PDF) live in a private S3 bucket
# fronted by CloudFront via Origin Access Control -- the bucket itself has no
# public access, only CloudFront can read from it.

resource "aws_s3_bucket" "static" {
  bucket = "${var.project_name}-static"
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "static" {
  name                              = "${var.project_name}-static-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ACM certificate for the static-assets custom domain. CloudFront requires
# certs to be issued in us-east-1 no matter which region the rest of the
# stack runs in.
#
# NOTE: this cert stays in PENDING_VALIDATION until the CNAME record in the
# `static_acm_certificate_validation_records` output is added at your
# external DNS provider (the domain isn't in Route 53, so Terraform can't
# create that record itself). The CloudFront distribution below can't attach
# a pending cert, so plan on a two-step apply the first time domain_name is
# set: apply once to create the cert and get the validation record, add that
# record externally, wait for ACM to show ISSUED, then apply again to create
# the distribution.
resource "aws_acm_certificate" "static" {
  count             = local.has_domain ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = local.static_fqdn
  validation_method = "DNS"
  tags              = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "static" {
  enabled = true
  comment = "${var.project_name} static assets"
  aliases = local.has_domain ? [local.static_fqdn] : []
  tags    = local.common_tags

  origin {
    domain_name              = aws_s3_bucket.static.bucket_regional_domain_name
    origin_id                = "s3-static"
    origin_access_control_id = aws_cloudfront_origin_access_control.static.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-static"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    # AWS managed "CachingOptimized" policy -- long TTLs, gzip/brotli aware.
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = local.has_domain ? false : true
    acm_certificate_arn            = local.has_domain ? aws_acm_certificate.static[0].arn : null
    ssl_support_method             = local.has_domain ? "sni-only" : null
    minimum_protocol_version       = local.has_domain ? "TLSv1.2_2021" : null
  }
}

data "aws_iam_policy_document" "static_bucket_policy" {
  statement {
    sid       = "AllowCloudFrontOAC"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.static.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.static_bucket_policy.json
}
