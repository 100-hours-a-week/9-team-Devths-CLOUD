terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Lambda 소스 코드 압축
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/src"
  output_path = "${path.module}/lambda_function.zip"
}

# SNS Topic - 보안 알림
resource "aws_sns_topic" "security_alerts" {
  name              = "${var.project_name}-security-alerts"
  display_name      = "Devths Security Alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-security-alerts"
    }
  )
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-discord-notifier-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-discord-notifier-role"
    }
  )
}

# Lambda IAM Policy - CloudWatch Logs 읽기 권한
resource "aws_iam_role_policy" "lambda_logs_policy" {
  name = "${var.project_name}-lambda-logs-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-discord-notifier:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:${var.log_group_name}:*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "discord_notifier" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-discord-notifier"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      DISCORD_WEBHOOK   = var.discord_webhook_url
      DISCORD_ROLE_ID   = var.discord_role_id
      LOG_GROUP_NAME    = var.log_group_name
      AWS_REGION_CUSTOM = var.aws_region
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-discord-notifier"
    }
  )
}

# Lambda Permission - SNS가 Lambda를 호출할 수 있도록 허용
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.security_alerts.arn
}

# SNS Topic Subscription - Lambda 구독
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.discord_notifier.arn
}

# CloudWatch Log Group - Lambda 로그
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.discord_notifier.function_name}"
  retention_in_days = 7

  tags = merge(
    var.common_tags,
    {
      Name = "/aws/lambda/${var.project_name}-discord-notifier"
    }
  )
}
