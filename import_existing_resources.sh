#!/bin/bash
# ===================================
# 기존 AWS 리소스를 Terraform State로 Import
# ===================================
#
# 이 스크립트는 AWS에 이미 존재하는 리소스를 Terraform 관리 대상으로 가져옵니다.
# 각 import 명령은 실패해도 계속 진행되도록 설정되어 있습니다.
#
# 사용법:
#   chmod +x import_existing_resources.sh
#   ./import_existing_resources.sh
#
# 참고:
#   - 이미 import된 리소스는 에러가 발생하지만 무시됩니다.
#   - import 후에는 반드시 'terraform plan'을 실행하여 차이점을 확인하세요.
# ===================================

set -e

echo "=========================================="
echo "Terraform Import Script"
echo "기존 AWS 리소스를 Terraform 관리 대상으로 가져옵니다."
echo "=========================================="
echo ""

# ===================================
# 1. VPC 및 네트워크 리소스
# ===================================
echo "[1/10] VPC 및 네트워크 리소스 import..."

terraform import aws_vpc.devths_prod vpc-0bb2d29ff2355366c || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

terraform import aws_internet_gateway.devths_prod_igw igw-0842d279eb193a3a7 || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

terraform import aws_subnet.devths_prod_public_01 subnet-0ba8692d5bdc017cf || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_subnet.devths_prod_public_02 subnet-07432ff70f598498f || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_subnet.devths_prod_private_01 subnet-0535a71f6c480bc94 || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_subnet.devths_prod_private_02 subnet-0c17b2d88bd104f9c || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

terraform import aws_default_route_table.devths_prod_default rtb-0bb9edfc4f43d320b || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_route_table.devths_prod_public rtb-0076ddb9973ed5089 || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_route_table_association.devths_prod_public_01 rtbassoc-025d82d143d3e49e2 || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_route_table_association.devths_prod_public_02 rtbassoc-0463205bb1d620d21 || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

terraform import aws_security_group.devths_prod_ec2 sg-0e544263677241912 || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ VPC 및 네트워크 리소스 import 완료"
echo ""

# ===================================
# 2. EC2 인스턴스 및 EIP
# ===================================
echo "[2/10] EC2 인스턴스 및 EIP import..."

terraform import aws_instance.devths_prod_app i-064af00509dc0e49c || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_eip.devths_prod_app_eip eipalloc-01761fb75a3b7e0a5 || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ EC2 인스턴스 및 EIP import 완료"
echo ""

# ===================================
# 3. IAM 역할 및 인스턴스 프로필
# ===================================
echo "[3/10] IAM 역할 및 인스턴스 프로필 import..."

terraform import aws_iam_role.ec2_prod Devths-EC2-Prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_instance_profile.ec2_prod Devths-EC2-Prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_role.codedeploy_prod Devths-CodeDeploy-Prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ IAM 역할 및 인스턴스 프로필 import 완료"
echo ""

# ===================================
# 4. IAM 정책
# ===================================
echo "[4/10] IAM 정책 import..."

terraform import aws_iam_policy.s3_artifact_access arn:aws:iam::015932244909:policy/S3-Access-Devths-artifact-prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_policy.ec2_parameter_store arn:aws:iam::015932244909:policy/EC2-ParameterStore-Prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_policy.ec2_log_s3 arn:aws:iam::015932244909:policy/EC2-LogS3 || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_policy.ec2_audit_ssm arn:aws:iam::015932244909:policy/EC2-Audit-SSM || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_policy.github_actions_deploy arn:aws:iam::015932244909:policy/GitHub-Actions-CodeDeploy-Policy || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ IAM 정책 import 완료"
echo ""

# ===================================
# 5. IAM Policy Attachments (EC2 역할)
# ===================================
echo "[5/10] IAM Policy Attachments (EC2 역할) import..."

# AWS 관리형 정책
terraform import aws_iam_role_policy_attachment.ec2_ssm_managed Devths-EC2-Prod/arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_role_policy_attachment.ec2_codedeploy Devths-EC2-Prod/arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

# 커스텀 정책
terraform import aws_iam_role_policy_attachment.ec2_s3_artifact Devths-EC2-Prod/arn:aws:iam::015932244909:policy/S3-Access-Devths-artifact-prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_role_policy_attachment.ec2_parameter_store Devths-EC2-Prod/arn:aws:iam::015932244909:policy/EC2-ParameterStore-Prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_role_policy_attachment.ec2_log_s3 Devths-EC2-Prod/arn:aws:iam::015932244909:policy/EC2-LogS3 || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_role_policy_attachment.ec2_audit_ssm Devths-EC2-Prod/arn:aws:iam::015932244909:policy/EC2-Audit-SSM || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ IAM Policy Attachments (EC2 역할) import 완료"
echo ""

# ===================================
# 6. IAM Policy Attachments (CodeDeploy 역할)
# ===================================
echo "[6/10] IAM Policy Attachments (CodeDeploy 역할) import..."

terraform import aws_iam_role_policy_attachment.codedeploy_managed Devths-CodeDeploy-Prod/arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_role_policy_attachment.s3_artifact_access Devths-CodeDeploy-Prod/arn:aws:iam::015932244909:policy/S3-Access-Devths-artifact-prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ IAM Policy Attachments (CodeDeploy 역할) import 완료"
echo ""

# ===================================
# 6.5. IAM User Policy Attachments (GitHub Actions)
# ===================================
echo "[6.5/10] IAM User Policy Attachments (GitHub Actions) import..."

terraform import aws_iam_user_policy_attachment.github_actions_deploy github-Actions/arn:aws:iam::015932244909:policy/GitHub-Actions-CodeDeploy-Policy || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_iam_user_policy_attachment.github_actions_s3 github-Actions/arn:aws:iam::015932244909:policy/S3-Access-Devths-artifact-prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ IAM User Policy Attachments (GitHub Actions) import 완료"
echo ""

# ===================================
# 7. S3 Buckets 및 설정
# ===================================
echo "[7/11] S3 Buckets 및 설정 import..."

# Artifact Bucket
terraform import aws_s3_bucket.devths_prod_deploy devths-artifact-prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_s3_bucket_versioning.devths_prod_deploy_versioning devths-artifact-prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_s3_bucket_lifecycle_configuration.devths_prod_deploy_lifecycle devths-artifact-prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_s3_bucket_public_access_block.devths_prod_deploy_public_access devths-artifact-prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_s3_bucket_server_side_encryption_configuration.devths_prod_deploy_encryption devths-artifact-prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

# SSM Log Bucket
terraform import aws_s3_bucket.devths_ssm_log devths-ssm-log || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_s3_bucket_lifecycle_configuration.devths_ssm_log_lifecycle devths-ssm-log || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_s3_bucket_public_access_block.devths_ssm_log_public_access devths-ssm-log || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_s3_bucket_server_side_encryption_configuration.devths_ssm_log_encryption devths-ssm-log || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ S3 Buckets 및 설정 import 완료"
echo ""

# ===================================
# 8. CodeDeploy 배포 그룹
# ===================================
echo "[8/11] CodeDeploy 배포 그룹 import..."
echo "  ℹ CodeDeploy Applications (Devhts-V1-FE, Devhts-V1-BE, Devhts-V1-AI)는 수동 생성된 리소스로 import 불필요"

terraform import aws_codedeploy_deployment_group.fe_prod_group Devhts-V1-FE:Devths-V1-FE-Prod-Group || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_codedeploy_deployment_group.be_prod_group Devhts-V1-BE:Devths-V1-BE-Prod-Group || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_codedeploy_deployment_group.ai_prod_group Devhts-V1-AI:Devths-V1-AI-Prod-Group || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ CodeDeploy 배포 그룹 import 완료"
echo ""

# ===================================
# 9. SSM 및 CloudWatch
# ===================================
echo "[9/11] SSM 및 CloudWatch import..."

terraform import aws_ssm_document.session_manager_prefs SSM-SessionManagerRunShell-V1-PROD || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

terraform import aws_cloudwatch_log_group.ssm_session_logs SSMSessionManagerLogGroup || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_cloudwatch_log_metric_filter.dangerous_commands DangerousCommandCount || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

terraform import aws_cloudwatch_metric_alarm.dangerous_command_alert Alert-Dangerous-Keyword || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_cloudwatch_metric_alarm.cpu_60_alert CPU-60-Alert-Prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_cloudwatch_metric_alarm.ebs_under_20_alert EBS-Under-20-Prod || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ SSM 및 CloudWatch import 완료"
echo ""

# ===================================
# 10. Route53 레코드
# ===================================
echo "[10/11] Route53 레코드 import..."
echo "  ℹ Route53 Hosted Zone은 data source로 참조되어 import 불필요"

# Route53 Zone ID를 먼저 확인해야 합니다
ZONE_ID="Z092923335TM9BWMNP3GX"

terraform import aws_route53_record.devths_prod_www ${ZONE_ID}_www.devths.com_A || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_route53_record.devths_prod_api ${ZONE_ID}_api.devths.com_A || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."
terraform import aws_route53_record.devths_prod_ai ${ZONE_ID}_ai.devths.com_A || echo "  ⚠ 이미 import되었거나 존재하지 않습니다."

echo "  ✓ Route53 레코드 import 완료"
echo ""

# ===================================
# 완료
# ===================================
echo "=========================================="
echo "✓ Import 완료!"
echo "=========================================="
echo ""
echo "다음 단계:"
echo "  1. terraform plan 을 실행하여 차이점을 확인하세요"
echo "  2. 차이가 있다면 코드를 수정하거나 terraform apply로 적용하세요"
echo ""
echo "참고사항:"
echo "  - 모든 리소스가 Terraform으로 관리됩니다"
echo "  - CodeDeploy Applications (Devhts-V1-FE/BE/AI)는 수동 생성된 리소스입니다"
echo ""
