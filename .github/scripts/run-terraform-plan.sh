#!/usr/bin/env bash

set -euo pipefail

stack_dir="${1:?stack directory is required}"
stack_key="${stack_dir#terraform/infrastructure/}"
backend_key="${stack_key}/terraform.tfstate"
workspace_root="${GITHUB_WORKSPACE:-$(pwd)}"
workdir="${workspace_root}/${stack_dir}"
temp_root="${RUNNER_TEMP:-/tmp}"
temp_var_file=""

cleanup() {
  if [[ -n "${temp_var_file}" && -f "${temp_var_file}" ]]; then
    rm -f "${temp_var_file}"
  fi
}

trap cleanup EXIT

if [[ ! -d "${workdir}" ]]; then
  echo "Terraform stack directory not found: ${workdir}" >&2
  exit 1
fi

case "${stack_key}" in
  nonprod/dev)
    secret_tfvars="${TFVARS_NONPROD_DEV:-}"
    ;;
  nonprod/monitoring)
    secret_tfvars="${TFVARS_NONPROD_MONITORING:-}"
    ;;
  nonprod/staging)
    secret_tfvars="${TFVARS_NONPROD_STAGING:-}"
    ;;
  prod/app)
    secret_tfvars="${TFVARS_PROD_APP:-}"
    ;;
  prod/monitoring)
    secret_tfvars="${TFVARS_PROD_MONITORING:-}"
    ;;
  *)
    secret_tfvars=""
    ;;
esac

var_file_args=()

if [[ -f "${workdir}/secrets.tfvars" ]]; then
  var_file_args+=("-var-file=secrets.tfvars")
fi

if [[ -n "${secret_tfvars}" ]]; then
  temp_var_file="$(mktemp "${temp_root}/terraform-${stack_key//\//-}.XXXXXX.tfvars")"
  printf '%s\n' "${secret_tfvars}" > "${temp_var_file}"
  var_file_args+=("-var-file=${temp_var_file}")
fi

case "${stack_key}" in
  nonprod/dev|nonprod/staging|prod/app)
    if [[ ! -f "${workdir}/secrets.tfvars" && -z "${secret_tfvars}" ]]; then
      echo "Required tfvars are missing for ${stack_key}. Add secrets.tfvars or configure the matching TFVARS secret." >&2
      exit 1
    fi
    ;;
  nonprod/monitoring)
    if [[ -z "${secret_tfvars}" ]]; then
      echo "TFVARS_NONPROD_MONITORING secret is required for nonprod/monitoring plan." >&2
      exit 1
    fi
    ;;
  prod/monitoring)
    if [[ -z "${secret_tfvars}" ]]; then
      echo "TFVARS_PROD_MONITORING secret is required for prod/monitoring plan." >&2
      exit 1
    fi
    ;;
esac

echo "::group::terraform init (${stack_key})"
# Backend 설정은 각 스택의 main.tf에 정의되어 있음
terraform -chdir="${workdir}" init \
  -input=false \
  -no-color
echo "::endgroup::"

echo "::group::terraform plan (${stack_key})"
terraform -chdir="${workdir}" plan \
  -input=false \
  -lock-timeout=5m \
  -no-color \
  "${var_file_args[@]}"
echo "::endgroup::"
