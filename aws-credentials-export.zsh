#!/bin/zsh

# AWS Credentials Export Script for IAM Roles Anywhere
# This script fetches temporary AWS credentials using certificate-based authentication
# and exports them as environment variables.

# =============================================================================
# CONFIGURATION - Replace these values with your actual paths and ARNs
# =============================================================================

# Path to the directory containing certificates and aws_signing_helper
CERTS_DIR="${HOME}/path/to/certs"

# Certificate and key paths
CERTIFICATE="${CERTS_DIR}/client-cert.pem"
PRIVATE_KEY="${CERTS_DIR}/private-key.pem"

# Path to aws_signing_helper binary
AWS_SIGNING_HELPER="${CERTS_DIR}/aws_signing_helper"

# AWS IAM Roles Anywhere ARNs (replace with values from your AWS setup)
TRUST_ANCHOR_ARN="arn:aws:rolesanywhere:REGION:ACCOUNT_ID:trust-anchor/TRUST_ANCHOR_ID"
PROFILE_ARN="arn:aws:rolesanywhere:REGION:ACCOUNT_ID:profile/PROFILE_ID"
ROLE_ARN="arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"

# =============================================================================
# SCRIPT LOGIC - No need to modify below this line
# =============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_error() {
    echo "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo "${GREEN}SUCCESS: $1${NC}"
}

print_info() {
    echo "${YELLOW}INFO: $1${NC}"
}

# Validate that required files exist
if [[ ! -f "${AWS_SIGNING_HELPER}" ]]; then
    print_error "aws_signing_helper not found at: ${AWS_SIGNING_HELPER}"
    print_info "Download it from: https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html"
    return 1 2>/dev/null || exit 1
fi

if [[ ! -x "${AWS_SIGNING_HELPER}" ]]; then
    print_error "aws_signing_helper is not executable: ${AWS_SIGNING_HELPER}"
    print_info "Run: chmod +x ${AWS_SIGNING_HELPER}"
    return 1 2>/dev/null || exit 1
fi

if [[ ! -f "${CERTIFICATE}" ]]; then
    print_error "Certificate not found at: ${CERTIFICATE}"
    return 1 2>/dev/null || exit 1
fi

if [[ ! -f "${PRIVATE_KEY}" ]]; then
    print_error "Private key not found at: ${PRIVATE_KEY}"
    return 1 2>/dev/null || exit 1
fi

# Check if ARNs have been configured
if [[ "${TRUST_ANCHOR_ARN}" == *"TRUST_ANCHOR_ID"* ]] || \
   [[ "${PROFILE_ARN}" == *"PROFILE_ID"* ]] || \
   [[ "${ROLE_ARN}" == *"ROLE_NAME"* ]]; then
    print_error "Please configure the ARNs in this script before running"
    print_info "Edit this file and replace the placeholder ARN values with your actual AWS ARNs"
    return 1 2>/dev/null || exit 1
fi

print_info "Fetching AWS credentials via IAM Roles Anywhere..."

# Fetch credentials using aws_signing_helper
CREDENTIALS_JSON=$(${AWS_SIGNING_HELPER} credential-process \
    --certificate "${CERTIFICATE}" \
    --private-key "${PRIVATE_KEY}" \
    --trust-anchor-arn "${TRUST_ANCHOR_ARN}" \
    --profile-arn "${PROFILE_ARN}" \
    --role-arn "${ROLE_ARN}" 2>&1)

# Check if the command was successful
if [[ $? -ne 0 ]]; then
    print_error "Failed to fetch credentials"
    echo "${CREDENTIALS_JSON}" >&2
    return 1 2>/dev/null || exit 1
fi

# Parse the JSON response
ACCESS_KEY_ID=$(echo "${CREDENTIALS_JSON}" | grep -o '"AccessKeyId":"[^"]*"' | cut -d'"' -f4)
SECRET_ACCESS_KEY=$(echo "${CREDENTIALS_JSON}" | grep -o '"SecretAccessKey":"[^"]*"' | cut -d'"' -f4)
SESSION_TOKEN=$(echo "${CREDENTIALS_JSON}" | grep -o '"SessionToken":"[^"]*"' | cut -d'"' -f4)
EXPIRATION=$(echo "${CREDENTIALS_JSON}" | grep -o '"Expiration":"[^"]*"' | cut -d'"' -f4)

# Validate that we got the credentials
if [[ -z "${ACCESS_KEY_ID}" ]] || [[ -z "${SECRET_ACCESS_KEY}" ]] || [[ -z "${SESSION_TOKEN}" ]]; then
    print_error "Failed to parse credentials from response"
    echo "Response: ${CREDENTIALS_JSON}" >&2
    return 1 2>/dev/null || exit 1
fi

# Export the credentials
export AWS_ACCESS_KEY_ID="${ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${SECRET_ACCESS_KEY}"
export AWS_SESSION_TOKEN="${SESSION_TOKEN}"

# Print success message
print_success "AWS credentials have been exported to environment variables"
print_info "Credentials expire at: ${EXPIRATION}"

# If sourced, also output the export commands for eval
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] || [[ -n "${ZSH_EVAL_CONTEXT}" && "${ZSH_EVAL_CONTEXT}" =~ :file$ ]]; then
    # Script is being sourced - credentials are already exported
    :
else
    # Script is being executed - output export commands for eval
    echo "export AWS_ACCESS_KEY_ID='${ACCESS_KEY_ID}'"
    echo "export AWS_SECRET_ACCESS_KEY='${SECRET_ACCESS_KEY}'"
    echo "export AWS_SESSION_TOKEN='${SESSION_TOKEN}'"
fi
