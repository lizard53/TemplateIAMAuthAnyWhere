# AWS IAM Roles Anywhere - PKI Authentication

A secure implementation of Public Key Infrastructure (PKI) for AWS IAM Roles Anywhere, enabling certificate-based authentication from macOS to AWS accounts without long-term access keys.

## Overview

This project demonstrates how to authenticate to AWS using X.509 certificates instead of traditional IAM access keys. By leveraging AWS IAM Roles Anywhere, you can obtain temporary AWS credentials using self-signed certificates, providing enhanced security for workloads running outside of AWS.

## Features

- Self-signed PKI infrastructure for AWS authentication
- Automated credential generation and export
- macOS Keychain integration
- X.509 v3 certificate support
- Temporary credential management via IAM Roles Anywhere

## Prerequisites

- macOS (Apple Silicon or Intel)
- OpenSSL
- AWS CLI
- [aws_signing_helper](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html)
- GitHub CLI (optional, for repository management)

## Quick Start

### 1. Generate Certificates

```bash
# Create certificates directory
mkdir -p certs
cd certs

# Generate root CA
openssl genrsa -out root-ca-key.pem 4096
openssl req -new -x509 -days 3650 -key root-ca-key.pem -out root-ca-cert.pem -config openssl.cnf -extensions v3_ca

# Generate client certificate
openssl genrsa -out private-key.pem 2048
openssl req -new -key private-key.pem -out client-csr.pem -subj "/C=US/ST=Washington/L=Seattle/O=Personal/OU=Personal/CN=MacStudio"
openssl x509 -req -days 365 -in client-csr.pem -CA root-ca-cert.pem -CAkey root-ca-key.pem -CAcreateserial -out client-cert.pem -extfile openssl.cnf -extensions v3_client
```

### 2. Configure AWS IAM Roles Anywhere

```bash
# Create Trust Anchor (upload root CA certificate)
aws rolesanywhere create-trust-anchor \
  --name "Personal-Mac-CA" \
  --source sourceType=CERTIFICATE_BUNDLE,sourceData={x509CertificateData="$(cat root-ca-cert.pem)"}

# Create Profile
aws rolesanywhere create-profile \
  --name "Personal-Mac-Profile" \
  --role-arns "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
```

### 3. Obtain Temporary Credentials

```bash
# Using the automated script
source ~/aws-credentials-export.zsh

# Or manually with aws_signing_helper
./aws_signing_helper credential-process \
  --certificate client-cert.pem \
  --private-key private-key.pem \
  --trust-anchor-arn arn:aws:rolesanywhere:REGION:ACCOUNT_ID:trust-anchor/TA_ID \
  --profile-arn arn:aws:rolesanywhere:REGION:ACCOUNT_ID:profile/PROFILE_ID \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
```

## Project Structure

```
.
├── README.md                 # This file
├── CLAUDE.md                 # Detailed implementation guide
├── .gitignore               # Excludes certificates from version control
├── certs/                   # Certificate storage (not in git)
│   ├── openssl.cnf         # OpenSSL v3 configuration
│   ├── root-ca-cert.pem    # Root CA certificate
│   ├── root-ca-key.pem     # Root CA private key
│   ├── client-cert.pem     # Client certificate
│   ├── private-key.pem     # Client private key
│   └── aws_signing_helper  # AWS credential helper
└── scripts/                 # Automation scripts (optional)
```

## Security Considerations

- Private keys are excluded from version control via `.gitignore`
- Root CA private key should be stored securely and kept offline when not in use
- Client certificates have limited validity (365 days recommended)
- All certificates must be X.509 v3 with proper extensions
- Temporary credentials expire automatically

## Documentation

For detailed setup instructions, troubleshooting, and architecture diagrams, see [CLAUDE.md](CLAUDE.md).

Key topics covered:
- Complete certificate generation workflow
- macOS Keychain integration
- AWS IAM Roles Anywhere configuration
- Automated credential export script
- Common issues and solutions
- Security best practices

## How It Works

1. Generate a self-signed root CA certificate
2. Register the root CA as a Trust Anchor in AWS IAM Roles Anywhere
3. Generate client certificates signed by the root CA
4. Use `aws_signing_helper` to authenticate with the client certificate
5. Receive temporary AWS credentials (AccessKeyId, SecretAccessKey, SessionToken)
6. Use credentials to interact with AWS services

## Benefits

- **No Long-Term Credentials**: Eliminates the need for static IAM access keys
- **Automatic Rotation**: Temporary credentials expire automatically
- **Certificate-Based Auth**: Leverages PKI for strong authentication
- **Audit Trail**: Certificate usage is logged in AWS CloudTrail
- **Flexible**: Works with any workload outside of AWS

## License

This project is for personal use and demonstration purposes.

## Additional Resources

- [AWS IAM Roles Anywhere Documentation](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/introduction.html)
- [AWS Signing Helper](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
