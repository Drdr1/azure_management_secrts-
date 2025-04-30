#!/bin/bash
# Script to deploy the Azure Function code after Terraform has created the infrastructure

# Get the Function App name and resource group from Terraform output
FUNCTION_APP_NAME=$(terraform output -raw function_app_name)
RESOURCE_GROUP=$(terraform output -raw function_app_resource_group)

# Check if email notifications are enabled
if [ "$FUNCTION_APP_NAME" == "Email notifications disabled" ]; then
  echo "Email notifications are disabled. Skipping function deployment."
  exit 0
fi

# Create temporary directory for function code
mkdir -p temp_function/EmailNotification

# Create function.json
cat > temp_function/EmailNotification/function.json << 'EOF'
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    }
  ]
}
EOF

# Create index.js
cat > temp_function/EmailNotification/index.js << 'EOF'
const sgMail = require('@sendgrid/mail');

module.exports = async function (context, req) {
    context.log('JavaScript HTTP trigger function processed a request.');
    
    try {
        // Check if this is a validation event
        if (req.body && req.body.length > 0 && req.body[0].eventType === 'Microsoft.EventGrid.SubscriptionValidationEvent') {
            context.log('Handling validation event');
            const validationEvent = req.body[0];
            const validationCode = validationEvent.data.validationCode;
            
            // Return the validation code to confirm the subscription
            context.res = {
                status: 200,
                body: { validationResponse: validationCode }
            };
            return;
        }
        
        // Handle regular event
        const eventData = req.body[0] || {};
        const data = eventData.data || {};
        
        if (!data.ObjectName || !data.VaultName) {
            context.res = {
                status: 400,
                body: "Invalid event data. Missing required fields."
            };
            return;
        }
        
        // Format expiration date
        let expirationDate = "Unknown";
        if (data.EXP) {
            const expDate = new Date(data.EXP * 1000); // Convert from Unix timestamp
            expirationDate = expDate.toISOString().split('T')[0]; // Format as YYYY-MM-DD
        }
        
        // Set up email
        sgMail.setApiKey(process.env.SENDGRID_API_KEY);
        
        const recipients = process.env.EMAIL_RECIPIENTS.split(',');
        
        const msg = {
            to: recipients,
            from: process.env.EMAIL_FROM,
            subject: `Secret Expiration Alert: ${data.ObjectName}`,
            html: `
                <h2>Secret Expiration Alert</h2>
                <p>The following secret is nearing expiration:</p>
                <p><strong>Key Vault:</strong> ${data.VaultName}</p>
                <p><strong>Secret Name:</strong> ${data.ObjectName}</p>
                <p><strong>Expiration Date:</strong> ${expirationDate}</p>
                <p>Please take action to rotate this secret before it expires.</p>
            `,
        };
        
        // Send email
        await sgMail.send(msg);
        
        context.res = {
            status: 200,
            body: "Email notification sent successfully"
        };
    } catch (error) {
        context.log.error('Error sending email:', error);
        context.res = {
            status: 500,
            body: `Error sending email notification: ${error.message}`
        };
    }
};
EOF

# Create package.json
cat > temp_function/EmailNotification/package.json << 'EOF'
{
  "name": "email-notification-function",
  "version": "1.0.0",
  "description": "Azure Function to send email notifications for expiring secrets",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "@sendgrid/mail": "^7.7.0"
  },
  "author": "",
  "license": "MIT"
}
EOF

# Navigate to the function directory
cd temp_function/EmailNotification

# Install dependencies
echo "Installing dependencies..."
npm install

# Create a zip file of the function
cd ..
echo "Creating function package..."
zip -r function.zip EmailNotification

# Deploy the function to Azure
echo "Deploying function to $FUNCTION_APP_NAME..."
az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --src function.zip

# Clean up
cd ..
rm -rf temp_function

# Get the function URL and key
echo "Getting function URL and key..."
FUNCTION_KEY=$(az functionapp function keys list \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --function-name "EmailNotification" \
  --query "default" -o tsv)

FUNCTION_URL="https://$FUNCTION_APP_NAME.azurewebsites.net/api/EmailNotification?code=$FUNCTION_KEY"

echo ""
echo "Function deployed successfully!"
echo ""
echo "To update the Event Grid subscription to use the function, run:"
echo "az eventgrid event-subscription update \\"
echo "  --name sub-secret-near-expiry \\"
echo "  --source-resource-id /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.EventGrid/systemTopics/evgt-keyvault-* \\"
echo "  --endpoint $FUNCTION_URL"
echo ""
echo "Or update it in the Azure Portal."