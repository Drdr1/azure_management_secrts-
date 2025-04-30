# Azure Key Vault Secret Management & Expiration Notification System

This solution automates the management of Azure Key Vault secrets, App Registrations (Service Principals), and Azure DevOps service connections, with automatic email notifications when secrets are nearing expiration.

## Solution Overview

![Architecture Diagram](https://i.imgur.com/JGXnLSw.png)

The solution includes:

1. **Azure Key Vault** for secure storage of secrets
2. **Azure AD App Registration** and Service Principal creation
3. **Azure DevOps Service Connection** setup using the Service Principal
4. **Event Grid** subscription for monitoring secret expiration events
5. **Azure Function** for processing events and sending notifications
6. **SendGrid** integration for email delivery

## Prerequisites

- Azure subscription with contributor access
- Azure CLI installed and authenticated
- Terraform v1.0 or later
- SendGrid account with verified sender
- Azure DevOps organization and project

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/azure-secret-management.git
cd azure-secret-management
```

### 2. Configure Variables

Create a `terraform.tfvars` file with your specific values:

```hcl
# Resource naming and location
resource_group_name    = "keyvault-automation-rg"
location               = "East US"
key_vault_name_prefix  = "kv-auto"
app_registration_name  = "terraform-service-principal"

# Secret expiration settings
secret_expiry_days            = 365
notification_days_before_expiry = 30

# Azure DevOps settings
azure_devops_org_url       = "https://dev.azure.com/your-organization"
azure_devops_pat           = "your-personal-access-token" # Keep this secure!
azure_devops_project_name  = "YourProject"
service_connection_name    = "Terraform-Azure-Connection"

# Notification settings
email_recipients = [
  "your-email@example.com"
]
slack_webhook_url        = "" # Optional
use_email_notifications  = true
use_slack_notifications  = false

# SendGrid Email Configuration
sendgrid_api_key = "your-sendgrid-api-key" # Keep this secure!
email_from       = "your-verified-sender@example.com"
```

### 3. Deploy Infrastructure

Initialize and apply the Terraform configuration:

```bash
terraform init
terraform apply
```

### 4. Deploy Function App Code

After Terraform has created the infrastructure, deploy the Function App code:

```bash
chmod +x deploy_function.sh
./deploy_function.sh
```

### 5. Update Event Grid Subscription

Follow the instructions output by the deployment script to update the Event Grid subscription to use your Function App.

### 6. Test the Solution

Create a test secret with a short expiration time:

```bash
# Get Key Vault name from Terraform output
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)

# Create a secret that expires in 2 minutes
az keyvault secret set --vault-name $KEY_VAULT_NAME \
  --name "test-expiring-secret" \
  --value "test-value" \
  --expires $(date -u -d "2 minutes" '+%Y-%m-%dT%H:%M:%SZ')
```

## How It Works

1. **Secret Creation**: Secrets are stored in Azure Key Vault with expiration dates.

2. **Automatic Monitoring**: Azure Key Vault monitors secrets for upcoming expiration.

3. **Event Generation**: When a secret is nearing expiration, Key Vault generates a `SecretNearExpiry` event.

4. **Event Processing**: Event Grid captures the event and routes it to the Azure Function.

5. **Notification**: The Function processes the event and sends an email notification with details about the expiring secret.

## Security Best Practices

1. **Secure Storage of Credentials**:
   - Never commit `terraform.tfvars` to source control
   - Use Azure Key Vault or environment variables for sensitive values
   - Add `terraform.tfvars` and `.terraform/` to `.gitignore`

2. **Access Control**:
   - Use the principle of least privilege for all service principals
   - Regularly review and audit access to the Key Vault

3. **Secret Rotation**:
   - Implement a process for rotating secrets when notified
   - Consider automating secret rotation where possible

## Maintenance

### Regular Tasks

1. **Monitor Function App Logs**: Check for any errors or issues in the notification process.

2. **Update Node.js Version**: Keep the Function App's Node.js version current with supported versions.

3. **Verify SendGrid Configuration**: Ensure your SendGrid API key and sender email remain valid.

4. **Review Secret Expiration Policies**: Adjust expiration periods based on your security requirements.

### Troubleshooting

#### Email Notifications Not Received

1. Check Function App logs for errors:
   ```bash
   az functionapp logs tail --name <function-app-name> --resource-group <resource-group-name>
   ```

2. Verify SendGrid sender verification:
   - Log in to SendGrid
   - Go to Settings > Sender Authentication
   - Ensure your sender email is verified

3. Test the Function directly:
   ```bash
   # Get Function URL
   FUNCTION_URL="<your-function-url-with-code>"
   
   # Create test event
   cat > event.json << EOF
   [{
     "id": "test-event-id",
     "eventType": "Microsoft.KeyVault.SecretNearExpiry",
     "subject": "/secrets/test-secret",
     "data": {
       "VaultName": "<your-key-vault-name>",
       "ObjectType": "Secret",
       "ObjectName": "test-secret",
       "Version": "",
       "NBF": null,
       "EXP": $(date -d "2 minutes" +%s)
     },
     "eventTime": "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
   }]
   EOF
   
   # Test function
   curl -X POST -H "Content-Type: application/json" -d @event.json $FUNCTION_URL
   ```

#### Event Grid Subscription Issues

1. Check Event Grid subscription status:
   ```bash
   az eventgrid event-subscription show \
     --name sub-secret-near-expiry \
     --source-resource-id /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.EventGrid/systemTopics/<event-grid-topic-name>
   ```

2. Recreate the subscription if needed:
   ```bash
   az eventgrid event-subscription create \
     --name sub-secret-near-expiry \
     --source-resource-id /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.EventGrid/systemTopics/<event-grid-topic-name> \
     --endpoint <function-url> \
     --included-event-types Microsoft.KeyVault.SecretNearExpiry Microsoft.KeyVault.SecretExpired
   ```

## Extending the Solution

### Add Slack Notifications

1. Create a Slack webhook URL in your Slack workspace
2. Update `terraform.tfvars` to enable Slack notifications:
   ```hcl
   use_slack_notifications = true
   slack_webhook_url = "https://hooks.slack.com/services/..."
   ```
3. Reapply the Terraform configuration

### Automate Secret Rotation

Consider extending this solution to automatically rotate secrets when they're nearing expiration:

1. Modify the Function App code to generate new secrets
2. Update the relevant services with the new secret values
3. Store the new secrets in Key Vault with updated expiration dates

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- HashiCorp for Terraform
- Microsoft Azure for cloud services
- SendGrid for email delivery services