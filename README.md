### Storage Account and Key Vault Automation in Azure
This project provides a PowerShell-based solution to automate the creation and configuration of Azure Storage Accounts and Key Vaults. It is designed to help teams deploy secure, consistent, and scalable resources across different Azure environments, minimizing manual setup efforts and enforcing best practices.

The automation covers:
- Provisioning Storage Accounts with configurable options (SKU, replication, network rules, etc.)
- Creating Azure Key Vaults with secure access policies
- Tagging resources for cost tracking and governance
- Error handling and idempotent deployment to support repeated executions

This repository can be used as a starting point for building larger infrastructure automation frameworks, or as a standalone tool for simplifying storage and secrets management in Azure.

### Getting Started
1. Clone the repository.
2. Update the parameters in the PowerShell script as needed (subscription ID, resource group, location, etc.).
3. Run the script using Azure PowerShell or Azure Cloud Shell.

### Prerequisites
- Azure PowerShell module (Az)
- Appropriate permissions to create resources in the target Azure subscription.
