#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Get the environment argument from the first parameter
ENVIRONMENT="${1:-}"

# Show usage help and list available environments if no argument or --help is passed
if [[ -z "${ENVIRONMENT}" || "${ENVIRONMENT}" == "--help" ]]; then
  cat <<EOF
Usage:
  $0 <environment-to-deploy> <flags>

List of environments:
  $(ls environments/)

Available flags:
  -d | --dry-run    Run without applying changes
  -u | --upsert     Create or update resources
  -v | --verbose    Print generated ApplicationSet YAML
EOF
  exit 1
fi
shift

# Initialize flag variables
FLAGS=()
VERBOSE=false

# Parse additional command-line flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dry-run)
      FLAGS+=("--dry-run")
      shift
      ;;
    -u|--upsert)
      FLAGS+=("--upsert")
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unexpected argument: $1" >&2
      exit 1
      ;;
  esac
done

# Load environment-specific variables
ENV_FILE="environments/${ENVIRONMENT}/shell.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file '${ENV_FILE}' not found" >&2
  exit 1
fi

# The path is dynamic, so we define a ShellCheck exception
# shellcheck source=/dev/null
source "${ENV_FILE}"

# Vault configuration
REPO_VAULT_PASSWORD_PATH="secret/example/${ENVIRONMENT}/argo"
REPO_VAULT_PASSWORD_KEY="example-key"

REPO_PASSWORD=$(vault kv get --field="${REPO_VAULT_PASSWORD_KEY}" "${REPO_VAULT_PASSWORD_PATH}")

# Validate REPO_PASSWORD was retrieved correctly
if [[ -z "${REPO_PASSWORD}" ]]; then
  echo "Failed to retrieve REPO_PASSWORD from Vault at path '${REPO_VAULT_PASSWORD_PATH}'" >&2
  exit 1
fi

# Required variables exported for envsubst
export APPSET_NAMESPACE
export ARGOCD_DOMAIN
export ARGOCD_NAMESPACE
export CLUSTER_NAME
export CLUSTER_URL
export ENVIRONMENT
export PROJECT_NAME

# Generate the ApplicationSet YAML
APPLICATIONSET_FILE=$(mktemp)
envsubst < "applicationsets/template.yaml" > "${APPLICATIONSET_FILE}"

# Log in to ArgoCD using SSO
argocd --grpc-web login --sso "${ARGOCD_DOMAIN}"

# Add repository to ArgoCD
REPO_URL="https://github.com/your-org/your-repo.git"

argocd repo add "${REPO_URL}" \
  --password "${REPO_PASSWORD}" \
  --name "${PROJECT_NAME}"

# Create the ArgoCD project
argocd --grpc-web proj create "${PROJECT_NAME}-${ENVIRONMENT}" \
  --dest '*,*' \
  --src '*' \
  --allow-cluster-resource '*/*' \
  --allow-namespaced-resource '*/*'

# Apply the ApplicationSet
argocd --grpc-web appset create "${APPLICATIONSET_FILE}" "${FLAGS[@]}"

# Optionally print the generated ApplicationSet file
if [[ "${VERBOSE}" == true ]]; then
  cat "${APPLICATIONSET_FILE}"
fi

# Cleanup
rm "${APPLICATIONSET_FILE}"

# Unset exported and internal variables
unset APPSET_NAMESPACE
unset ARGOCD_DOMAIN
unset ARGOCD_NAMESPACE
unset CLUSTER_NAME
unset CLUSTER_URL
unset ENVIRONMENT
unset PROJECT_NAME
unset FLAGS
unset VERBOSE
unset ENV_FILE
unset APPLICATIONSET_FILE
unset REPO_URL
unset REPO_PASSWORD
unset REPO_VAULT_PASSWORD_PATH
unset REPO_VAULT_PASSWORD_KEY
