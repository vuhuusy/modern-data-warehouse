################################################################################
# Local Values
################################################################################

locals {
  # Bucket naming: <project>-<env>-<name> or custom name
  bucket_name = var.use_prefix ? "${var.project}-${var.environment}-${var.bucket_name}" : var.bucket_name

  # Mandatory tags following enterprise standards
  mandatory_tags = {
    project       = var.project
    env           = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = var.managed_by
    resource_type = "s3"
    created_by    = "terraform"
    created_date  = formatdate("YYYYMMDD", timestamp())
  }

  # Merge mandatory tags with additional tags (mandatory tags take precedence)
  tags = merge(var.tags, local.mandatory_tags)

  # Logging prefix defaults to bucket name if not specified
  logging_prefix = var.logging_target_prefix != null ? var.logging_target_prefix : "${local.bucket_name}/"

  # Determine if any policy should be attached
  attach_any_policy = var.attach_policy || var.attach_deny_insecure_transport_policy || var.attach_require_latest_tls_policy
}

################################################################################
# S3 Bucket
################################################################################

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = local.tags

  lifecycle {
    # Prevent accidental deletion in production
    prevent_destroy = false
  }
}

################################################################################
# Public Access Block (Security)
################################################################################

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_access.block_public_acls
  block_public_policy     = var.block_public_access.block_public_policy
  ignore_public_acls      = var.block_public_access.ignore_public_acls
  restrict_public_buckets = var.block_public_access.restrict_public_buckets
}

################################################################################
# Bucket Versioning
################################################################################

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.versioning_mfa_delete ? "Enabled" : "Disabled"
  }
}

################################################################################
# Server-Side Encryption
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_configuration.sse_algorithm
      kms_master_key_id = var.encryption_configuration.kms_master_key_id
    }
    bucket_key_enabled = var.encryption_configuration.bucket_key_enabled
  }
}

################################################################################
# Object Ownership
################################################################################

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }

  depends_on = [aws_s3_bucket_public_access_block.this]
}

################################################################################
# Bucket Policy
################################################################################

data "aws_iam_policy_document" "deny_insecure_transport" {
  count = var.attach_deny_insecure_transport_policy ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "require_latest_tls" {
  count = var.attach_require_latest_tls_policy ? 1 : 0

  statement {
    sid    = "RequireLatestTLS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}

data "aws_iam_policy_document" "combined" {
  count = local.attach_any_policy ? 1 : 0

  source_policy_documents = compact([
    var.attach_deny_insecure_transport_policy ? data.aws_iam_policy_document.deny_insecure_transport[0].json : null,
    var.attach_require_latest_tls_policy ? data.aws_iam_policy_document.require_latest_tls[0].json : null,
    var.attach_policy ? var.policy : null
  ])
}

resource "aws_s3_bucket_policy" "this" {
  count = local.attach_any_policy ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.combined[0].json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

################################################################################
# Access Logging
################################################################################

resource "aws_s3_bucket_logging" "this" {
  count = var.logging_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_target_bucket
  target_prefix = local.logging_prefix
}

################################################################################
# Lifecycle Configuration
################################################################################

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.status

      # Filter block
      dynamic "filter" {
        for_each = rule.value.filter != null ? [rule.value.filter] : []

        content {
          prefix                   = filter.value.prefix
          object_size_greater_than = filter.value.object_size_greater_than
          object_size_less_than    = filter.value.object_size_less_than

          dynamic "tag" {
            for_each = filter.value.tags != null ? filter.value.tags : {}

            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      # Expiration
      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []

        content {
          days                         = expiration.value.days
          date                         = expiration.value.date
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      # Transitions
      dynamic "transition" {
        for_each = rule.value.transition != null ? rule.value.transition : []

        content {
          days          = transition.value.days
          date          = transition.value.date
          storage_class = transition.value.storage_class
        }
      }

      # Noncurrent version expiration
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []

        content {
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
        }
      }

      # Noncurrent version transitions
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition != null ? rule.value.noncurrent_version_transition : []

        content {
          noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

      # Abort incomplete multipart uploads
      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload != null ? [rule.value.abort_incomplete_multipart_upload] : []

        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

################################################################################
# CORS Configuration
################################################################################

resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      id              = cors_rule.value.id
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}
