#!/bin/bash

# Jenkins Plugin Installation Script
# This script lists the essential plugins needed for the healthcare app pipeline

echo "Jenkins Plugin Requirements for Healthcare App Pipeline"
echo "========================================================="

echo ""
echo "ESSENTIAL PLUGINS TO INSTALL:"
echo ""

# Core Pipeline Plugins
echo "1. PIPELINE & BUILD PLUGINS:"
echo "   [OK] Pipeline"
echo "   [OK] Pipeline Stage View"
echo "   [OK] Blue Ocean (blueocean)"
echo "   [OK] Pipeline: Multibranch"
echo "   [OK] Pipeline: Build Step"
echo ""

# Git & SCM Plugins
echo "2. SOURCE CONTROL PLUGINS:"
echo "   [OK] Git plugin"
echo "   [OK] GitHub plugin"
echo "   [OK] GitHub Branch Source"
echo "   [OK] Credentials plugin"
echo ""

# Docker & Kubernetes Plugins
echo "3. CONTAINER & DEPLOYMENT PLUGINS:"
echo "   [OK] Docker plugin"
echo "   [OK] Docker Pipeline"
echo "   [OK] Kubernetes plugin"
echo "   [OK] Kubernetes CLI"
echo ""

# Testing & Quality Plugins
echo "4. TESTING & QUALITY PLUGINS:"
echo "   [OK] SonarQube Scanner"
echo "   [OK] JUnit plugin"
echo "   [OK] HTML Publisher"
echo "   [OK] Test Results Analyzer"
echo ""

# Security & Monitoring Plugins
echo "5. SECURITY & MONITORING PLUGINS:"
echo "   [OK] OWASP Dependency-Check"
echo "   [OK] Warnings Next Generation"
echo "   [OK] Prometheus metrics"
echo "   [OK] Build Timeout"
echo ""

# Utility Plugins
echo "6. UTILITY PLUGINS:"
echo "   [OK] Timestamper"
echo "   [OK] AnsiColor"
echo "   [OK] Workspace Cleanup"
echo "   [OK] Build User Vars"
echo ""

echo "INSTALLATION METHODS:"
echo ""
echo "Method 1 - Via Jenkins UI:"
echo "1. Go to 'Manage Jenkins' → 'Manage Plugins'"
echo "2. Click 'Available' tab"
echo "3. Search for each plugin above"
echo "4. Check the box and click 'Install without restart'"
echo ""

echo "Method 2 - Auto-install via CLI:"
echo "You can install plugins automatically using Jenkins CLI"
echo ""

echo "Jenkins URLs:"
echo "Main Dashboard: http://localhost:8080"
echo "Plugin Manager: http://localhost:8080/pluginManager/"
echo "Blue Ocean: http://localhost:8080/blue"
echo ""

echo "QUICK START:"
echo "1. Install 'Blue Ocean' first (it includes many pipeline plugins)"
echo "2. Add Docker, Kubernetes, and SonarQube plugins"
echo "3. Configure credentials as per JENKINS_CREDENTIALS.md"
echo "4. Create your pipeline job"
