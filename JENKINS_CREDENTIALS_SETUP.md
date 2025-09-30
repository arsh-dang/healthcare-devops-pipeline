# Jenkins Credentials Setup Guide

## Required Jenkins Credentials

To ensure the healthcare application pipeline works correctly, you need to configure the following credentials in Jenkins:

### 1. **SMTP Email Credentials** (`smtp-credentials`)
- **Type**: Username/Password
- **ID**: `smtp-credentials`
- **Username**: `arshdang2@gmail.com` (or your Gmail address)
- **Password**: Your Gmail App Password (not your regular password)

**Gmail App Password Setup:**
1. Go to Google Account settings
2. Enable 2-Factor Authentication
3. Generate an App Password for "Mail"
4. Use this App Password in Jenkins (not your regular Gmail password)

### 2. **Datadog API Key** (`datadog-api-key`)
- **Type**: Secret Text
- **ID**: `datadog-api-key`
- **Value**: Your Datadog API key

### 3. **SonarQube Token** (`sonarqube-token`)
- **Type**: Secret Text
- **ID**: `sonarqube-token`
- **Value**: Your SonarQube authentication token

## How to Add Credentials in Jenkins

1. **Navigate to Jenkins Dashboard**
2. **Go to**: Manage Jenkins → Manage Credentials
3. **Select**: Global credentials (unrestricted)
4. **Click**: Add Credentials

### For SMTP Credentials:
- **Kind**: Username with password
- **Scope**: Global
- **Username**: `arshdang2@gmail.com`
- **Password**: Your Gmail App Password
- **ID**: `smtp-credentials`
- **Description**: SMTP credentials for email notifications

### For Datadog API Key:
- **Kind**: Secret text
- **Scope**: Global
- **Secret**: Your Datadog API key
- **ID**: `datadog-api-key`
- **Description**: Datadog API key for monitoring

### For SonarQube Token:
- **Kind**: Secret text
- **Scope**: Global
- **Secret**: Your SonarQube token
- **ID**: `sonarqube-token`
- **Description**: SonarQube authentication token

## Security Benefits

✅ **No sensitive data in Git**: All passwords and API keys are stored securely in Jenkins
✅ **Environment variables**: Terraform receives credentials via `TF_VAR_*` environment variables
✅ **Encrypted storage**: Jenkins encrypts all credential values
✅ **Access control**: Jenkins manages credential access permissions

## Pipeline Usage

The Jenkins pipeline will automatically:
1. Load credentials using `withCredentials()`
2. Pass them to Terraform as environment variables:
   - `TF_VAR_smtp_username` → SMTP username
   - `TF_VAR_smtp_password` → SMTP password  
   - `TF_VAR_smtp_from_email` → Email sender
   - `TF_VAR_datadog_api_key` → Datadog API key

## Email Notifications

Once configured, the pipeline will send email notifications to:
- **Critical Alerts**: `arshdang2@gmail.com`
- **Warning Alerts**: `arshdang2@gmail.com`
- **Info Alerts**: `arshdang2@gmail.com`

## Datadog Integration

With the API key configured, the pipeline will:
- Create Datadog dashboards
- Set up monitoring alerts
- Send metrics and events to Datadog
- Create synthetic tests

## Troubleshooting

### Email Not Working:
- Verify Gmail App Password is correct
- Check 2-Factor Authentication is enabled
- Ensure `smtp-credentials` ID matches exactly

### Datadog Not Working:
- Verify API key is valid and active
- Check `datadog-api-key` ID matches exactly
- Ensure Datadog account has proper permissions

### SonarQube Not Working:
- Verify token has correct permissions
- Check SonarQube server is accessible
- Ensure `sonarqube-token` ID matches exactly

## Testing Credentials

You can test the credentials by:
1. Running the Jenkins pipeline
2. Checking the "Datadog Setup" stage for API key validation
3. Monitoring email notifications during pipeline execution
4. Verifying SonarQube analysis completes successfully
