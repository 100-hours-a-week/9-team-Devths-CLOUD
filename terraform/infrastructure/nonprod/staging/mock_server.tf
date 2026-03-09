# ============================================================================
# Mock Server Artifact
# ============================================================================

# Local mock 디렉터리를 압축하여 artifact bucket에 업로드
data "archive_file" "mock_bundle" {
  type        = "zip"
  source_dir  = "${path.module}/../../../../mock"
  output_path = "${path.module}/.terraform/mock_bundle.zip"
  excludes    = [".claude/*", ".DS_Store"]
}

resource "aws_s3_object" "mock_bundle" {
  bucket      = data.terraform_remote_state.s3.outputs.artifact_bucket_name
  key         = "mock/mock-server-bundle.zip"
  source      = data.archive_file.mock_bundle.output_path
  source_hash = data.archive_file.mock_bundle.output_base64sha256
}
