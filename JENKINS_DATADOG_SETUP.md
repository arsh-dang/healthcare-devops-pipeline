# 🚀 Jenkins + Datadog Integration - Zero Configuration Setup

## ✅ What You Need to Do (Just 2 Steps!)

### Step 1: Add Datadog API Key to Jenkins
1. Go to your Jenkins dashboard
2. Click **"Manage Jenkins"** → **"Credentials"**
3. Click **"Global credentials"** → **"Add Credentials"**
4. Choose **"Secret text"**
5. Set **ID**: `datadog-api-key`
6. Set **Secret**: Your Datadog API key (get from [here](https://app.datadoghq.com/organization-settings/application-keys))
7. Click **"OK"**

### Step 2: Run the Jenkins Pipeline
That's it! Just run your Jenkins pipeline and everything will be set up automatically.

---

## 🤖 What Happens Automatically

When you run the Jenkins pipeline, it will:

### 1. **Datadog Setup Stage** (New!)
- ✅ Deploy Datadog infrastructure via Terraform
- ✅ Create comprehensive dashboards
- ✅ Set up 10 critical monitors
- ✅ Configure synthetic tests
- ✅ Send initial metrics

### 2. **All Existing Stages** (Enhanced!)
- ✅ **Build**: Sends build metrics to Datadog
- ✅ **Test**: Tracks test results and coverage
- ✅ **Deploy**: Monitors deployment status
- ✅ **Monitoring**: Sends completion events

### 3. **Complete Monitoring Stack**
- ✅ **2 Dashboards**: Healthcare app + Jenkins CI/CD
- ✅ **10 Alerts**: Error rates, performance, security, SLA
- ✅ **2 Synthetic Tests**: API health + frontend availability
- ✅ **Custom Metrics**: Application, database, business metrics

---

## 📊 What You Get

### Dashboards Created Automatically
1. **Healthcare Application Dashboard** (12 panels)
   - Application health, request rates, response times
   - Error rates, database performance
   - Infrastructure metrics (CPU, memory)
   - Business metrics (patients, SLA)
   - Security events, deployment status

2. **Jenkins CI/CD Dashboard** (4 panels)
   - Pipeline execution time
   - Test results tracking
   - Deployment success rate
   - Build health monitoring

### Monitors Created Automatically
- High Error Rate (> 5%)
- High Response Time (> 2s)
- Database Connection Issues
- High CPU/Memory Usage
- Service Unavailable
- Security Events
- SLA Breach
- Deployment Failures
- Jenkins Pipeline Failures

### Metrics Sent Automatically
- `healthcare.app.health` - Application health
- `healthcare.api.requests` - API request count
- `healthcare.api.errors` - API error count
- `healthcare.api.response_time` - Response time
- `mongodb.connections.*` - Database metrics
- `jenkins.build.*` - Build metrics
- `jenkins.tests.*` - Test results
- `jenkins.deployment.*` - Deployment status

---

## 🎯 Access Your Monitoring

After running the Jenkins pipeline, access your monitoring at:

- **Datadog Dashboard**: https://app.datadoghq.com/dashboard
- **Monitors**: https://app.datadoghq.com/monitors
- **Events**: https://app.datadoghq.com/events
- **Synthetics**: https://app.datadoghq.com/synthetics

---

## 🔧 Optional: Pre-Setup Validation

If you want to verify everything is ready before running the pipeline:

```bash
# Run the setup validation script
./setup-jenkins-datadog.sh
```

This will:
- ✅ Check all required files are present
- ✅ Make scripts executable
- ✅ Validate Jenkins pipeline syntax
- ✅ Provide setup instructions

---

## 🚨 Troubleshooting

### If Datadog Setup Fails
- The pipeline will continue without Datadog monitoring
- Check Jenkins console logs for details
- Verify the `datadog-api-key` credential is correct
- Ensure your Datadog API key has proper permissions

### If You See "Command Not Found" Errors
- The pipeline automatically makes scripts executable
- If issues persist, run: `chmod +x datadog/scripts/*.sh`

### If Terraform Fails
- Check that all required tools are installed (terraform, curl, jq)
- Verify the Datadog API key is valid
- Check Jenkins console logs for detailed error messages

---

## 📚 Advanced Configuration (Optional)

### Customize Dashboards
Edit `datadog/dashboards/healthcare-dashboard.json` and redeploy via Jenkins.

### Add More Monitors
Edit `datadog/alerts/healthcare-alerts.json` and redeploy via Jenkins.

### Modify Metrics
Update the Jenkins pipeline stages to send additional custom metrics.

---

## 🎉 Summary

**You literally just need to:**
1. Add the Datadog API key to Jenkins credentials
2. Run the Jenkins pipeline

**Everything else is automated:**
- ✅ Infrastructure deployment
- ✅ Dashboard creation
- ✅ Monitor setup
- ✅ Metrics collection
- ✅ Event tracking
- ✅ Synthetic testing

**That's it! Your healthcare application will have enterprise-grade monitoring with zero manual configuration.** 🚀
