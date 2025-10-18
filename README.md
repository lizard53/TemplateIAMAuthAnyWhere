# AWS IAM Roles Anywhere - PKI Authentication Template

**This is a template repository** that demonstrates how to implement Public Key Infrastructure (PKI) for AWS IAM Roles Anywhere, enabling certificate-based authentication from macOS to AWS accounts without long-term access keys.

## Overview

This template shows how to authenticate to AWS using X.509 certificates instead of traditional IAM access keys. By leveraging AWS IAM Roles Anywhere, you can obtain temporary AWS credentials using self-signed certificates, providing enhanced security for workloads running outside of AWS.

Use this repository as a reference and starting point for implementing PKI authentication in your own AWS environment.

## What's Included

- **Template OpenSSL Configuration** (`certs/openssl.cnf`) - Pre-configured for X.509 v3 certificates required by AWS IAM Roles Anywhere
- **Credential Export Script** (`aws-credentials-export.zsh`) - Automated script to fetch and export temporary AWS credentials
- **Comprehensive Documentation** (`CLAUDE.md`) - Detailed setup guide with examples, architecture diagrams, and troubleshooting
- **Example Commands** - All commands use placeholder values that you can replace with your own

## Features

- Self-signed PKI infrastructure for AWS authentication
- Automated credential generation and export script
- macOS Keychain integration support
- X.509 v3 certificate configuration
- Temporary credential management via IAM Roles Anywhere
- No hardcoded sensitive values - all examples use placeholders

## Prerequisites

- macOS (Apple Silicon or Intel)
- OpenSSL (for certificate generation)
- AWS CLI (for IAM Roles Anywhere setup)
- [aws_signing_helper](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html) (download instructions in CLAUDE.md)
- An AWS account with permissions to create IAM Roles Anywhere resources

## Getting Started

📚 **Follow the complete setup guide in [CLAUDE.md](CLAUDE.md)**

The CLAUDE.md file provides comprehensive step-by-step instructions including:

1. **Configure the OpenSSL template** (`certs/openssl.cnf`) with your organization details
2. **Generate PKI certificates** using the provided OpenSSL commands with examples
3. **Set up AWS IAM Roles Anywhere** resources (Trust Anchor, Profile, Role)
4. **Configure the credential export script** (`aws-credentials-export.zsh`) with your paths and ARNs
5. **Test and verify** your certificate-based authentication

All commands in CLAUDE.md use **placeholder values** with concrete examples showing what real values look like. Simply replace the placeholders with your actual configuration.

## Project Structure

```
.
├── README.md                     # This file - quick start guide
├── CLAUDE.md                     # Detailed implementation guide
├── aws-credentials-export.zsh    # Template credential automation script
├── .gitignore                    # Excludes certificates from version control
└── certs/                        # Certificate storage (not in git)
    ├── openssl.cnf               # OpenSSL v3 configuration template
    ├── root-ca-cert.pem          # Root CA certificate (generated)
    ├── root-ca-key.pem           # Root CA private key (generated)
    ├── client-cert.pem           # Client certificate (generated)
    ├── private-key.pem           # Client private key (generated)
    └── aws_signing_helper        # AWS credential helper (download separately)
```

## Security Considerations

- **No Hardcoded Secrets**: All examples use placeholder values - replace with your own
- **Private Keys Protected**: Excluded from version control via `.gitignore`
- **Root CA Security**: Root CA private key should be stored securely offline when not in use
- **Certificate Expiration**: Client certificates have limited validity (365 days recommended)
- **X.509 v3 Required**: AWS IAM Roles Anywhere requires v3 certificates with proper extensions
- **Automatic Rotation**: Temporary credentials expire automatically (typically 1 hour)
- **Audit Trail**: All certificate usage is logged in AWS CloudTrail

## Documentation

📖 **See [CLAUDE.md](CLAUDE.md) for comprehensive documentation**

The detailed guide includes:
- **Architecture Overview**: Mermaid diagrams showing the complete authentication flow
- **Step-by-Step Setup**: Detailed instructions with examples for each configuration value
- **Certificate Generation**: Complete OpenSSL commands with explanations
- **AWS Configuration**: How to create Trust Anchors, Profiles, and retrieve ARNs
- **macOS Keychain Integration**: Optional integration for secure certificate storage
- **Credential Automation**: How to configure and use the included script
- **Troubleshooting**: Common issues and their solutions
- **Security Best Practices**: Guidelines for secure PKI management

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

## Getting Help

- Review [CLAUDE.md](CLAUDE.md) for detailed documentation
- Check the "Common Issues" section in CLAUDE.md for troubleshooting
- Ensure all placeholder values have been replaced with your actual configuration

## License

This is a template repository for demonstration and educational purposes. Feel free to use it as a starting point for your own AWS IAM Roles Anywhere implementation.

## Additional Resources

- [AWS IAM Roles Anywhere Documentation](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/introduction.html)
- [AWS Signing Helper](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
