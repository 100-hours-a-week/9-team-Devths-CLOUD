#!/usr/bin/env bash
# ============================================================================
# Terraform K8s Plan Runner
# ============================================================================
# K8s 인프라 전용 Terraform plan 실행 스크립트
# - nonprod-k8s/*
# - prod-k8s/*
# ============================================================================

set -euo pipefail

stack_dir="${1:?stack directory is required}"
stack_key="${stack_dir#terraform/infrastructure/}"
workspace_root="${GITHUB_WORKSPACE:-$(pwd)}"
workdir="${workspace_root}/${stack_dir}"

# 디렉토리 존재 확인
if [[ ! -d "${workdir}" ]]; then
  echo "❌ Terraform stack directory not found: ${workdir}" >&2
  exit 1
fi

# K8s 스택인지 확인
if [[ ! "${stack_key}" =~ ^(nonprod-k8s|prod-k8s)/ ]]; then
  echo "❌ This script is only for K8s stacks (nonprod-k8s/* or prod-k8s/*)" >&2
  echo "   Provided: ${stack_key}" >&2
  exit 1
fi

echo "=========================================="
echo "Terraform K8s Plan"
echo "=========================================="
echo "Stack: ${stack_key}"
echo "Working directory: ${workdir}"
echo ""

# ============================================================================
# Terraform Init
# ============================================================================
echo "::group::terraform init (${stack_key})"
# Backend 설정은 각 스택의 main.tf에 정의되어 있음
terraform -chdir="${workdir}" init \
  -input=false \
  -no-color
echo "::endgroup::"

echo ""

# ============================================================================
# Terraform Plan
# ============================================================================
echo "::group::terraform plan (${stack_key})"
# K8s 스택은 secrets.tfvars가 필요하지 않음 (모든 설정이 코드에 있음)
terraform -chdir="${workdir}" plan \
  -input=false \
  -lock-timeout=5m \
  -no-color
echo "::endgroup::"

echo ""
echo "✅ Terraform K8s plan completed for ${stack_key}"
