# Azure Management Secrets with Terraform

This repository contains Terraform configurations to automate the management of **Azure Key Vault secrets**, **App Registrations (Service Principals)**, and **Azure DevOps service connections**. It also includes workflows to notify users via **email** or **Slack** when secrets are nearing expiration.

---

## **What Was Completed**

1. **Terraform Configurations**:
   - Created resources for:
     - **Azure Key Vault** to manage secrets.
     - **App Registrations (Service Principals)** to manage credentials.
     - **Azure DevOps service connections** to manage service endpoints.
   - Set up **Logic Apps**, **Automation Runbooks**, and **Azure Functions** to notify users about expiring secrets.

2. **GitHub Actions Workflow**:
   - Automated the deployment of Terraform configurations using GitHub Actions.
   - Integrated with **Jira** to track tasks and issues.

3. **Notifications**:
   - Configured **email** and **Slack** notifications for expiring secrets.

---

## **How to Run**

Follow these **step-by-step instructions** to set up and run the Terraform configuration:

---

### **Step 1: Prerequisites**

Before you begin, ensure you have the following:

1. **Azure Account**:
   - You need an Azure account with the necessary permissions to create resources.

2. **Service Principal**:
   - Create a Service Principal in Azure and grant it the **Contributor** role for your subscription.
   - Save the following details:
     - `ARM_CLIENT_ID`
     - `ARM_CLIENT_SECRET`
     - `ARM_SUBSCRIPTION_ID`
     - `ARM_TENANT_ID`

3. **GitHub Repository**:
   - Fork or clone this repository to your GitHub account.

4. **GitHub Secrets**:
   - Go to your repository > **Settings > Secrets and variables > Actions**.
   - Add the following secrets:
     - `ARM_CLIENT_ID`
     - `ARM_CLIENT_SECRET`
     - `ARM_SUBSCRIPTION_ID`
     - `ARM_TENANT_ID`

---

### **Step 2: Clone the Repository**

Clone the repository to your local machine:

```bash
git clone https://github.com/Drdr1/azure_management_secrts-.git
cd azure_management_secrts-
```
### **Step 3: Initialize Terraform**

```bash
terraform init
```

### **Step 4: Review the Terraform Plan**

```bash
terraform plan
```

### **Step 5: Apply the Terraform Configuration**

```bash
terraform apply -auto-approve
```

### **Step 6: Verify the Resources**

1- Go to the Azure Portal.

2- Navigate to the Resource Group specified in the configuration (secret-management-rg by default).

3- Verify that the following resources have been created:

. Azure Key Vault

. Logic Apps

. Automation Runbooks

. Azure Functions


### **Step 7: Run the GitHub Actions Workflow**

1- Push changes to the main branch of your repository.

2- Go to the Actions tab in your GitHub repository.

3- Verify that the workflow runs successfully and creates the resources in Azure.


### **Step 8: Monitor Notifications**

1- Check your email or Slack for notifications about expiring secrets.

2- If notifications are not working, verify the configurations for Logic Apps, Automation Runbooks, and Azure Functions.


### **Step 9: Clean Up**

To delete all the resources created by Terraform, run:

```bash
terraform destroy -auto-approve
```

---

## Terraform Configuration Overview :

### Key Files:

1- main.tf:

- Defines the main Terraform configuration, including the Resource Group and provider settings.

2- variables.tf:

- Contains input variables for the configuration (e.g., resource_group_name, location).

3- logic-apps.tf:

- Configures Logic Apps for sending notifications.

4- automation-runbooks.tf:

- Configures Automation Runbooks for checking expiring secrets.

5- azure-functions.tf:

- Configures Azure Functions for triggering notifications.

6- .github/workflows/terraform.yml:

- Defines the GitHub Actions workflow for automating Terraform deployments.

## How to Test the Solution :

### **Step 1: Create a Secret in Azure Key Vault**

- Go to the Azure Portal.

- Navigate to your Azure Key Vault.

- Create a new secret with an expiration date set to a few days in the future.

### **Step 2: Trigger the Automation Runbook or Azure Function**

 Automation Runbook:

- Go to the Azure Portal.

- Navigate to the Automation Account.

- Find the Runbook named check-expiring-secrets.

-Manually start the Runbook and verify that it sends an email notification.

- Azure Function:

- Go to the Azure Portal.

- Navigate to the Function App.

- Find the Function named CheckExpiringSecrets.

- Manually trigger the Function and verify that it sends a Slack or email notification.

### **Step 3: Verify Notifications**

Check your email or Slack for notifications about the expiring secret.








