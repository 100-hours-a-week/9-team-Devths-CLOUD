#!/bin/bash
# Terraform State Migration Script
# 기존 개별 리소스를 for_each 패턴으로 마이그레이션

set -e

echo "🔄 Starting Terraform state migration..."

# Developer Users
echo "📝 Migrating developer users..."
terraform state mv 'aws_iam_user.yun' 'aws_iam_user.developers["yun"]'
terraform state mv 'aws_iam_user.neon' 'aws_iam_user.developers["neon"]'
terraform state mv 'aws_iam_user.estar' 'aws_iam_user.developers["estar"]'

echo "📝 Migrating developer login profiles..."
terraform state mv 'aws_iam_user_login_profile.yun' 'aws_iam_user_login_profile.developers["yun"]'
terraform state mv 'aws_iam_user_login_profile.neon' 'aws_iam_user_login_profile.developers["neon"]'
terraform state mv 'aws_iam_user_login_profile.estar' 'aws_iam_user_login_profile.developers["estar"]'

echo "📝 Migrating developer group memberships..."
terraform state mv 'aws_iam_user_group_membership.yun_developers' 'aws_iam_user_group_membership.developers["yun"]'
terraform state mv 'aws_iam_user_group_membership.neon_developers' 'aws_iam_user_group_membership.developers["neon"]'
terraform state mv 'aws_iam_user_group_membership.estar_developers' 'aws_iam_user_group_membership.developers["estar"]'

# S3 Service Accounts
echo "📝 Migrating S3 service accounts..."
terraform state mv 'aws_iam_user.s3_service_dev' 'aws_iam_user.s3_service["dev"]'
terraform state mv 'aws_iam_user.s3_service_staging' 'aws_iam_user.s3_service["staging"]'
terraform state mv 'aws_iam_user.s3_service_prod' 'aws_iam_user.s3_service["prod"]'

echo "📝 Migrating S3 policies..."
terraform state mv 'aws_iam_policy.s3_storage_dev' 'aws_iam_policy.s3_storage_env["dev"]'
terraform state mv 'aws_iam_policy.s3_storage_staging' 'aws_iam_policy.s3_storage_env["staging"]'
terraform state mv 'aws_iam_policy.s3_storage_prod' 'aws_iam_policy.s3_storage_env["prod"]'

echo "📝 Migrating S3 policy attachments..."
terraform state mv 'aws_iam_user_policy_attachment.s3_service_dev' 'aws_iam_user_policy_attachment.s3_service["dev"]'
terraform state mv 'aws_iam_user_policy_attachment.s3_service_staging' 'aws_iam_user_policy_attachment.s3_service["staging"]'
terraform state mv 'aws_iam_user_policy_attachment.s3_service_prod' 'aws_iam_user_policy_attachment.s3_service["prod"]'

echo "📝 Migrating S3 service group memberships..."
terraform state mv 'aws_iam_user_group_membership.s3_service_dev' 'aws_iam_user_group_membership.s3_service["dev"]'
terraform state mv 'aws_iam_user_group_membership.s3_service_staging' 'aws_iam_user_group_membership.s3_service["staging"]'
terraform state mv 'aws_iam_user_group_membership.s3_service_prod' 'aws_iam_user_group_membership.s3_service["prod"]'

echo "✅ Migration completed successfully!"
echo "🔍 Running terraform plan to verify..."
terraform plan
