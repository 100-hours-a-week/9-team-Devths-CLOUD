# ===================================
# CodeDeploy 역할
# ===================================

resource "aws_iam_role" "codedeploy" {
  name = "${title(var.project_name)}-CodeDeploy-${title(var.environment)}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${title(var.project_name)}-CodeDeploy-${title(var.environment)}"
    }
  )
}


# ===================================
# CodeDeploy 정책
# ===================================

# CodeDeploy S3 Artifact 버킷 권한
resource "aws_iam_role_policy" "codedeploy_s3_artifact" {
  name = "${title(var.project_name)}-CodeDeploy-S3-Artifact-${title(var.environment)}"
  role = aws_iam_role.codedeploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = compact([
          var.artifact_bucket_arn,
          "${var.artifact_bucket_arn}/*",
          var.v1_artifact_bucket_arn != "" ? var.v1_artifact_bucket_arn : "",
          var.v1_artifact_bucket_arn != "" ? "${var.v1_artifact_bucket_arn}/*" : ""
        ])
      }
    ]
  })
}


# ===================================
# CodeDeploy 정책 연결
# ===================================

# CodeDeploy 권한
resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}
