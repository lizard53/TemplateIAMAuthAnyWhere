#!/bin/zsh

# AWS Console Federated URL Generator for IAM Roles Anywhere
# This script fetches temporary AWS credentials using certificate-based authentication
# and generates a federated console URL for direct browser access to the AWS Console.

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

# Console session duration (in seconds, max 43200 = 12 hours)
SESSION_DURATION="43200"

# Issuer name (your organization or identifier)
ISSUER="MyOrganization"

# =============================================================================
# SCRIPT LOGIC - No need to modify below this line
# =============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_url() {
    echo "${BLUE}$1${NC}"
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

# Check if required commands are available
if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed"
    return 1 2>/dev/null || exit 1
fi

if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed"
    print_info "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
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

# Parse the JSON response using jq
ACCESS_KEY_ID=$(echo "${CREDENTIALS_JSON}" | jq -r '.AccessKeyId')
SECRET_ACCESS_KEY=$(echo "${CREDENTIALS_JSON}" | jq -r '.SecretAccessKey')
SESSION_TOKEN=$(echo "${CREDENTIALS_JSON}" | jq -r '.SessionToken')
EXPIRATION=$(echo "${CREDENTIALS_JSON}" | jq -r '.Expiration')

# Validate that we got the credentials
if [[ -z "${ACCESS_KEY_ID}" ]] || [[ "${ACCESS_KEY_ID}" == "null" ]] || \
   [[ -z "${SECRET_ACCESS_KEY}" ]] || [[ "${SECRET_ACCESS_KEY}" == "null" ]] || \
   [[ -z "${SESSION_TOKEN}" ]] || [[ "${SESSION_TOKEN}" == "null" ]]; then
    print_error "Failed to parse credentials from response"
    echo "Response: ${CREDENTIALS_JSON}" >&2
    return 1 2>/dev/null || exit 1
fi

print_success "AWS credentials obtained successfully"
print_info "Credentials expire at: ${EXPIRATION}"

# Construct the session JSON for federation
SESSION_JSON=$(jq -n \
    --arg aki "${ACCESS_KEY_ID}" \
    --arg sak "${SECRET_ACCESS_KEY}" \
    --arg st "${SESSION_TOKEN}" \
    '{sessionId: $aki, sessionKey: $sak, sessionToken: $st}')

# URL encode the session JSON
SESSION_JSON_ENCODED=$(echo -n "${SESSION_JSON}" | jq -sRr @uri)

print_info "Requesting sign-in token from AWS federation endpoint..."

# Request sign-in token from AWS federation endpoint
SIGNIN_TOKEN_RESPONSE=$(curl -s -G "https://signin.aws.amazon.com/federation" \
    --data-urlencode "Action=getSigninToken" \
    --data-urlencode "SessionDuration=${SESSION_DURATION}" \
    --data-urlencode "Session=${SESSION_JSON}")

# Check if the request was successful
if [[ $? -ne 0 ]]; then
    print_error "Failed to request sign-in token"
    return 1 2>/dev/null || exit 1
fi

# Parse the sign-in token
SIGNIN_TOKEN=$(echo "${SIGNIN_TOKEN_RESPONSE}" | jq -r '.SigninToken')

if [[ -z "${SIGNIN_TOKEN}" ]] || [[ "${SIGNIN_TOKEN}" == "null" ]]; then
    print_error "Failed to obtain sign-in token"
    echo "Response: ${SIGNIN_TOKEN_RESPONSE}" >&2
    return 1 2>/dev/null || exit 1
fi

print_success "Sign-in token obtained successfully"

# URL encode the issuer and destination
ISSUER_ENCODED=$(echo -n "${ISSUER}" | jq -sRr @uri)
DESTINATION_ENCODED=$(echo -n "https://console.aws.amazon.com/" | jq -sRr @uri)

# Construct the federated console URL
CONSOLE_URL="https://signin.aws.amazon.com/federation?Action=login&Issuer=${ISSUER_ENCODED}&Destination=${DESTINATION_ENCODED}&SigninToken=${SIGNIN_TOKEN}"

print_success "Federated console URL generated successfully"
echo ""
print_info "Console URL (valid for ${SESSION_DURATION} seconds):"
echo ""
print_url "${CONSOLE_URL}"
echo ""
print_info "Copy the URL above and paste it into your browser to access the AWS Console"
print_info "Or run: open \"${CONSOLE_URL}\" (macOS) or xdg-open \"${CONSOLE_URL}\" (Linux)"
echo ""

# Detect OS and offer to open the URL automatically
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    read "REPLY?Open URL in default browser? (y/n) "
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        open "${CONSOLE_URL}"
        print_success "Opening AWS Console in your default browser..."
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    read "REPLY?Open URL in default browser? (y/n) "
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        xdg-open "${CONSOLE_URL}" 2>/dev/null || {
            print_error "xdg-open not available. Please copy the URL manually."
        }
        print_success "Opening AWS Console in your default browser..."
    fi
fi
