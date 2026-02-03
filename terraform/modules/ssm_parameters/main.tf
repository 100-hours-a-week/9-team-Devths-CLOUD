# Backend Parameters
resource "aws_ssm_parameter" "be_params" {
  for_each = local.be_params

  name        = "/${var.environment_prefix}/BE/${each.key}"
  description = each.value.description
  type        = each.value.type
  value       = each.value.value != null ? each.value.value : "PLACEHOLDER_${each.key}"

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
}

# AI Parameters
resource "aws_ssm_parameter" "ai_params" {
  for_each = local.ai_params

  name        = "/${var.environment_prefix}/AI/${each.key}"
  description = each.value.description
  type        = each.value.type
  value       = each.value.value != null ? each.value.value : "PLACEHOLDER_${each.key}"

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
}

locals {
  # Backend Parameters
  be_params = {
    DB_USERNAME = {
      type        = "SecureString"
      description = "Production DB username"
      value       = null
    }
    DB_PASSWORD = {
      type        = "SecureString"
      description = "Production DB password"
      value       = null
    }
    DB_URL = {
      type        = "SecureString"
      description = "Production DB URL"
      value       = null
    }
    JWT_SECRET = {
      type        = "SecureString"
      description = "JWT secret key"
      value       = null
    }
    JWT_ACCESS_TOKEN_EXPIRATION = {
      type        = "SecureString"
      description = "JWT access token expiration"
      value       = null
    }
    JWT_REFRESH_TOKEN_EXPIRATION = {
      type        = "SecureString"
      description = "JWT refresh token expiration"
      value       = null
    }
    JWT_TEMP_TOKEN_EXPIRATION = {
      type        = "SecureString"
      description = "JWT temp token expiration"
      value       = null
    }
    GOOGLE_CLIENT_ID = {
      type        = "SecureString"
      description = "Google OAuth client ID"
      value       = null
    }
    GOOGLE_CLIENT_SECRET = {
      type        = "SecureString"
      description = "Google OAuth client secret"
      value       = null
    }
    GOOGLE_REDIRECT_URI = {
      type        = "SecureString"
      description = "Google OAuth redirect URI"
      value       = null
    }
    ENCRYPTION_AES_KEY = {
      type        = "SecureString"
      description = "AES encryption key"
      value       = null
    }
    S3_ACCESS_KEY = {
      type        = "SecureString"
      description = "S3 access key"
      value       = null
    }
    S3_SECRET_KEY = {
      type        = "SecureString"
      description = "S3 secret key"
      value       = null
    }
    S3_BUCKET = {
      type        = "SecureString"
      description = "S3 bucket name"
      value       = null
    }
    S3_REGION = {
      type        = "SecureString"
      description = "S3 region"
      value       = null
    }
    FASTAPI_BASE_URL = {
      type        = "SecureString"
      description = "FastAPI base URL"
      value       = null
    }
    CORS_ALLOWED_ORIGINS = {
      type        = "SecureString"
      description = "CORS allowed origins"
      value       = null
    }
    SPRING_JPA_DDL_AUTO = {
      type        = "SecureString"
      description = "Spring JPA DDL auto"
      value       = null
    }
    CONNECTION_TIMEOUT = {
      type        = "SecureString"
      description = "DB connection timeout"
      value       = null
    }
    IDLE_TIMEOUT = {
      type        = "SecureString"
      description = "DB idle timeout"
      value       = null
    }
    MAXIMUM_POOL_SIZE = {
      type        = "SecureString"
      description = "DB maximum pool size"
      value       = null
    }
    MINIMUM_IDLE = {
      type        = "SecureString"
      description = "DB minimum idle"
      value       = null
    }
    CW_ENABLED = {
      type        = "SecureString"
      description = "CloudWatch enabled"
      value       = null
    }
    CW_NAME_SPACE = {
      type        = "SecureString"
      description = "CloudWatch namespace"
      value       = null
    }
  }

  # AI Parameters
  ai_params = {
    API_KEY = {
      type        = "SecureString"
      description = "AI API key"
      value       = null
    }
    HOST = {
      type        = "SecureString"
      description = "AI host"
      value       = null
    }
    PORT = {
      type        = "SecureString"
      description = "AI port"
      value       = null
    }
    GOOGLE_API_KEY = {
      type        = "SecureString"
      description = "Google API key"
      value       = null
    }
    GCP_VLLM_BASE_URL = {
      type        = "SecureString"
      description = "GCP VLLM base URL"
      value       = null
    }
    VLLM_VERIFY_SSL = {
      type        = "SecureString"
      description = "VLLM verify SSL"
      value       = null
    }
    CLOVA_OCR_API_URL = {
      type        = "SecureString"
      description = "Clova OCR API URL"
      value       = null
    }
    CLOVA_OCR_SECRET_KEY = {
      type        = "SecureString"
      description = "Clova OCR secret key"
      value       = null
    }
    LANGFUSE_BASE_URL = {
      type        = "SecureString"
      description = "Langfuse base URL"
      value       = null
    }
    LANGFUSE_HOST = {
      type        = "SecureString"
      description = "Langfuse host"
      value       = null
    }
    LANGFUSE_PUBLIC_KEY = {
      type        = "SecureString"
      description = "Langfuse public key"
      value       = null
    }
    LANGFUSE_SECRET_KEY = {
      type        = "SecureString"
      description = "Langfuse secret key"
      value       = null
    }
  }
}
