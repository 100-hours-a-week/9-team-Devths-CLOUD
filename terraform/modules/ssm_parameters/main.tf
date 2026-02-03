# KMS Key for SSM Parameter Encryption
resource "aws_kms_key" "ssm_params" {
  description             = "KMS key for SSM Parameter Store encryption - ${var.environment_prefix}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.common_tags,
    {
      Name        = "ssm-params-${lower(var.environment_prefix)}"
      Environment = var.environment_prefix
      Purpose     = "SSM Parameter Store Encryption"
    }
  )
}

# KMS Key Alias
resource "aws_kms_alias" "ssm_params" {
  name          = "alias/ssm-params-${lower(var.environment_prefix)}"
  target_key_id = aws_kms_key.ssm_params.key_id
}

# Backend Parameters
resource "aws_ssm_parameter" "be_params" {
  for_each = local.be_params

  name        = "/${var.environment_prefix}/BE/${each.key}"
  description = each.value.description
  type        = each.value.type
  value       = lookup(var.be_parameter_values, each.key, "PLACEHOLDER_${each.key}")
  key_id      = aws_kms_key.ssm_params.key_id

  tags = merge(
    var.common_tags,
    {
      Name        = "/${var.environment_prefix}/BE/${each.key}"
      Service     = "Backend"
      Environment = var.environment_prefix
    }
  )

  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [aws_kms_key.ssm_params]
}

# AI Parameters
resource "aws_ssm_parameter" "ai_params" {
  for_each = local.ai_params

  name        = "/${var.environment_prefix}/AI/${each.key}"
  description = each.value.description
  type        = each.value.type
  value       = lookup(var.ai_parameter_values, each.key, "PLACEHOLDER_${each.key}")
  key_id      = aws_kms_key.ssm_params.key_id

  tags = merge(
    var.common_tags,
    {
      Name        = "/${var.environment_prefix}/AI/${each.key}"
      Service     = "AI"
      Environment = var.environment_prefix
    }
  )

  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [aws_kms_key.ssm_params]
}

locals {
  # Backend Parameters
  be_params = {
    DB_USERNAME = {
      type        = "SecureString"
      description = "Production DB username"
    }
    DB_PASSWORD = {
      type        = "SecureString"
      description = "Production DB password"
    }
    DB_URL = {
      type        = "SecureString"
      description = "Production DB URL"
    }
    JWT_SECRET = {
      type        = "SecureString"
      description = "JWT secret key"
    }
    JWT_ACCESS_TOKEN_EXPIRATION = {
      type        = "SecureString"
      description = "JWT access token expiration"
    }
    JWT_REFRESH_TOKEN_EXPIRATION = {
      type        = "SecureString"
      description = "JWT refresh token expiration"
    }
    JWT_TEMP_TOKEN_EXPIRATION = {
      type        = "SecureString"
      description = "JWT temp token expiration"
    }
    GOOGLE_CLIENT_ID = {
      type        = "SecureString"
      description = "Google OAuth client ID"
    }
    GOOGLE_CLIENT_SECRET = {
      type        = "SecureString"
      description = "Google OAuth client secret"
    }
    GOOGLE_REDIRECT_URI = {
      type        = "SecureString"
      description = "Google OAuth redirect URI"
    }
    ENCRYPTION_AES_KEY = {
      type        = "SecureString"
      description = "AES encryption key"
    }
    S3_ACCESS_KEY = {
      type        = "SecureString"
      description = "S3 access key"
    }
    S3_SECRET_KEY = {
      type        = "SecureString"
      description = "S3 secret key"
    }
    S3_BUCKET = {
      type        = "SecureString"
      description = "S3 bucket name"
    }
    S3_REGION = {
      type        = "SecureString"
      description = "S3 region"
    }
    FASTAPI_BASE_URL = {
      type        = "SecureString"
      description = "FastAPI base URL"
    }
    CORS_ALLOWED_ORIGINS = {
      type        = "SecureString"
      description = "CORS allowed origins"
    }
    SPRING_JPA_DDL_AUTO = {
      type        = "SecureString"
      description = "Spring JPA DDL auto"
    }
    CONNECTION_TIMEOUT = {
      type        = "SecureString"
      description = "DB connection timeout"
    }
    IDLE_TIMEOUT = {
      type        = "SecureString"
      description = "DB idle timeout"
    }
    MAXIMUM_POOL_SIZE = {
      type        = "SecureString"
      description = "DB maximum pool size"
    }
    MINIMUM_IDLE = {
      type        = "SecureString"
      description = "DB minimum idle"
    }
    CW_ENABLED = {
      type        = "SecureString"
      description = "CloudWatch enabled"
    }
    CW_NAME_SPACE = {
      type        = "SecureString"
      description = "CloudWatch namespace"
    }
    LOG_LEVEL = {
      type        = "SecureString"
      description = "Log Level"
    }
  }

  # AI Parameters
  ai_params = {
    API_KEY = {
      type        = "SecureString"
      description = "AI API key"
    }
    HOST = {
      type        = "SecureString"
      description = "AI host"
    }
    PORT = {
      type        = "SecureString"
      description = "AI port"
    }
    GOOGLE_API_KEY = {
      type        = "SecureString"
      description = "Google API key"
    }
    GCP_VLLM_BASE_URL = {
      type        = "SecureString"
      description = "GCP VLLM base URL"
    }
    VLLM_VERIFY_SSL = {
      type        = "SecureString"
      description = "VLLM verify SSL"
    }
    CLOVA_OCR_API_URL = {
      type        = "SecureString"
      description = "Clova OCR API URL"
    }
    CLOVA_OCR_SECRET_KEY = {
      type        = "SecureString"
      description = "Clova OCR secret key"
    }
    LANGFUSE_BASE_URL = {
      type        = "SecureString"
      description = "Langfuse base URL"
    }
    LANGFUSE_HOST = {
      type        = "SecureString"
      description = "Langfuse host"
    }
    LANGFUSE_PUBLIC_KEY = {
      type        = "SecureString"
      description = "Langfuse public key"
    }
    LANGFUSE_SECRET_KEY = {
      type        = "SecureString"
      description = "Langfuse secret key"
    }
  }
}
