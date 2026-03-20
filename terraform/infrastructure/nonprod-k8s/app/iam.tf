# IAM Module
module "iam" {
  source = "../../../modules/iam"

  project_name             = var.project_name
  environment              = var.environment
  environment_prefix       = "NonProdK8s"
  kms_key_arn              = data.terraform_remote_state.ssm.outputs.kms_key_arn
  artifact_bucket_arn      = data.terraform_remote_state.network.outputs.artifact_bucket_arn
  v1_artifact_bucket_arn   = ""
  storage_bucket_arn       = data.terraform_remote_state.network.outputs.artifact_bucket_arn
  cloudwatch_log_group_arn = data.terraform_remote_state.ssm.outputs.cloudwatch_log_group_arn
  ssm_log_bucket_arn       = data.terraform_remote_state.ssm.outputs.ssm_log_bucket_arn
  tempo_bucket_arn         = try(data.terraform_remote_state.network.outputs.tempo_bucket_arn, "")
  loki_bucket_arn          = try(data.terraform_remote_state.network.outputs.loki_bucket_arn, "")
  common_tags              = var.common_tags
}

# Additional IAM policy for K8s worker nodes to access join command from SSM
resource "aws_iam_role_policy" "k8s_join_command_access" {
  name = "${title(var.project_name)}-K8s-Join-Command-Access-${local.iam_name_suffix}"
  role = module.iam.ec2_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter${local.join_command_ssm_path}"
        ]
      }
    ]
  })
}