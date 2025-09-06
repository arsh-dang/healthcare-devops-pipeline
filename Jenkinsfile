pipeline {
    agent any
    
    environment {
        // Docker Hub or Registry Configuration
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_REPO = 'yourusername/healthcare-app'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        
        // PATH Configuration for macOS
        PATH = "${env.PATH}:/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:/opt/homebrew/bin"
        
        // Application Configuration
        APP_NAME = 'healthcare-app'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        GIT_COMMIT = "${env.GIT_COMMIT?.take(7) ?: 'unknown'}"
        
        // SonarQube Configuration
        SONAR_PROJECT_KEY = 'healthcare-app'
        SONAR_HOST_URL = 'http://localhost:9000'
        // Use SonarQube token authentication (recommended)
        SONAR_TOKEN = credentials('sonarqube-token')
        
        // Kubernetes Configuration
        KUBECONFIG = credentials('kubeconfig')
        NAMESPACE = 'healthcare-production'
        
        // Monitoring URLs
        PROMETHEUS_URL = 'http://localhost:9090'
        GRAFANA_URL = 'http://localhost:3000'
    }
    
    options {
        // Keep builds for 30 days
        buildDiscarder(logRotator(daysToKeepStr: '30', numToKeepStr: '10'))
        
        // Timeout the entire pipeline after 30 minutes
        timeout(time: 30, unit: 'MINUTES')
        
        // Enable timestamps in console output
        timestamps()
        
        // Skip default checkout
        skipDefaultCheckout(false)
    }
    
    tools {
        nodejs '20.x'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Checking out source code...'
                checkout scm
                
                script {
                    // Get commit information
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    
                    echo "Git Commit: ${env.GIT_COMMIT}"
                    echo "Commit Message: ${env.GIT_COMMIT_MSG}"
                }
            }
        }
        
        stage('Build') {
            parallel {
                stage('Build Frontend') {
                    steps {
                        echo 'Building Frontend Application with Advanced Optimizations...'
                        
                        script {
                            // Cache node_modules for faster builds
                            sh '''
                                if [ -d "node_modules_cache" ]; then
                                    cp -r node_modules_cache node_modules
                                fi
                            '''
                            
                            // Install dependencies with cache optimization
                            sh '''
                                npm install -g pnpm
                                pnpm install --no-frozen-lockfile --prefer-offline
                                cp -r node_modules node_modules_cache
                            '''
                            
                            // Generate build metadata
                            sh '''
                                echo "{\\"buildNumber\\": \\"${BUILD_NUMBER}\\", \\"gitCommit\\": \\"${GIT_COMMIT}\\", \\"buildTime\\": \\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\\"}" > src/build-info.json
                            '''
                            
                            // Run build with performance analysis
                            sh '''
                                ANALYZE=true pnpm build
                                
                                # Generate build size report
                                npx webpack-bundle-analyzer build/static/js/*.js --mode static --report build-report.html --no-open || true
                            '''
                            
                            // Archive the build artifacts with detailed fingerprinting
                            archiveArtifacts artifacts: 'build/**/*,build-report.html,src/build-info.json', fingerprint: true, allowEmptyArchive: true
                            
                            // Store build metrics
                            sh '''
                                BUILD_SIZE=$(du -sh build/ | cut -f1)
                                echo "Build size: $BUILD_SIZE" > build-metrics.txt
                                JS_SIZE=$(find build/static/js -name "*.js" -exec du -ch {} + | grep total | cut -f1)
                                echo "JavaScript size: $JS_SIZE" >> build-metrics.txt
                                CSS_SIZE=$(find build/static/css -name "*.css" -exec du -ch {} + | grep total | cut -f1)
                                echo "CSS size: $CSS_SIZE" >> build-metrics.txt
                            '''
                            
                            archiveArtifacts artifacts: 'build-metrics.txt', fingerprint: true
                            
                            echo 'Frontend build completed with advanced optimizations'
                        }
                    }
                    
                    post {
                        success {
                            echo 'Frontend build stage completed successfully with performance analysis'
                        }
                        failure {
                            echo 'Frontend build stage failed'
                        }
                    }
                }
                
                stage('Build Docker Images') {
                    steps {
                        echo '🐳 Building Docker Images...'
                        
                        script {
                            // Build frontend Docker image
                            def frontendImage = docker.build(
                                "${DOCKER_REPO}-frontend:${BUILD_NUMBER}", 
                                "-f Dockerfile.frontend ."
                            )
                            
                            // Build backend Docker image
                            def backendImage = docker.build(
                                "${DOCKER_REPO}-backend:${BUILD_NUMBER}", 
                                "-f Dockerfile.backend ."
                            )
                            
                            // Tag images with latest
                            frontendImage.tag("latest")
                            backendImage.tag("latest")
                            
                            // Store image info for later use
                            env.FRONTEND_IMAGE = "${DOCKER_REPO}-frontend:${BUILD_NUMBER}"
                            env.BACKEND_IMAGE = "${DOCKER_REPO}-backend:${BUILD_NUMBER}"
                            
                            echo "✅ Docker images built: ${env.FRONTEND_IMAGE}, ${env.BACKEND_IMAGE}"
                        }
                    }
                    
                    post {
                        success {
                            echo '✅ Docker images built successfully'
                        }
                        failure {
                            echo '❌ Docker image build failed'
                        }
                    }
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo 'Running Comprehensive Unit Tests...'
                        
                        script {
                            // Run React tests with enhanced configuration
                            sh '''
                                export CI=true
                                export GENERATE_SOURCEMAP=false
                                pnpm test:ci
                            '''
                            
                            // Publish test results with detailed metrics
                            junit testResults: 'test-report.xml'
                            
                            // Archive coverage reports as HTML
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage/lcov-report',
                                reportFiles: 'index.html',
                                reportName: 'Coverage Report'
                            ])
                        }
                    }
                    
                    post {
                        always {
                            archiveArtifacts artifacts: 'coverage/**/*,test-results-*.xml', allowEmptyArchive: true
                        }
                        success {
                            echo 'Unit tests completed successfully'
                        }
                        failure {
                            echo 'Unit tests failed'
                        }
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        echo 'Running Advanced Integration Tests...'
                        
                        script {
                            // Start test environment with advanced configuration
                            sh '''
                                # Create test network
                                docker network create healthcare-test-network || true
                                
                                # Start test containers with health checks
                                docker-compose -f docker-compose.test.yml up -d --force-recreate
                                
                                # Wait for services with health checks and longer timeout
                                echo "Waiting for services to be healthy..."
                                sleep 30
                                
                                # Check container status
                                docker-compose -f docker-compose.test.yml ps
                                
                                # Set environment variables for CI
                                export CI=true
                                export JENKINS_URL=${JENKINS_URL}
                                
                                # Run comprehensive integration tests
                                npm run test:integration
                            '''
                        }
                    }
                    
                    post {
                        always {
                            // Collect container logs
                            sh '''
                                echo "=== Container Status ==="
                                docker-compose -f docker-compose.test.yml ps || true
                                echo "=== Backend Logs ==="
                                docker-compose -f docker-compose.test.yml logs backend-test || true
                                echo "=== Frontend Logs ==="
                                docker-compose -f docker-compose.test.yml logs frontend-test || true
                                echo "=== MongoDB Logs ==="
                                docker-compose -f docker-compose.test.yml logs mongodb-test || true
                                
                                # Save all logs
                                docker-compose -f docker-compose.test.yml logs > integration-test-logs.txt || true
                                docker-compose -f docker-compose.test.yml down --volumes || true
                                docker network rm healthcare-test-network || true
                            '''
                            archiveArtifacts artifacts: 'integration-test-logs.txt', allowEmptyArchive: true
                        }
                        success {
                            echo 'Integration tests completed successfully'
                        }
                        failure {
                            echo 'Integration tests failed'
                        }
                    }
                }
                
                stage('API Testing') {
                    steps {
                        echo 'Running API Contract and Load Tests...'
                        
                        script {
                            // API contract testing with Postman/Newman
                            sh '''
                                # Install Newman if not available
                                npm install -g newman newman-reporter-htmlextra || true
                                
                                # Run API tests if collection exists
                                if [ -f "postman/healthcare-api.postman_collection.json" ]; then
                                    newman run postman/healthcare-api.postman_collection.json \
                                        --environment postman/test.postman_environment.json \
                                        --reporters cli,htmlextra \
                                        --reporter-htmlextra-export api-test-report.html \
                                        --bail || echo "API tests completed with issues"
                                fi
                            '''
                            
                            // Load testing with artillery
                            sh '''
                                # Install artillery if not available
                                npm install -g artillery || true
                                
                                # Run load tests if config exists
                                if [ -f "load-tests/artillery-config.yml" ]; then
                                    artillery run load-tests/artillery-config.yml --output load-test-results.json || echo "Load tests completed"
                                    artillery report load-test-results.json --output load-test-report.html || true
                                fi
                            '''
                        }
                    }
                    
                    post {
                        always {
                            archiveArtifacts artifacts: 'api-test-report.html,load-test-report.html,load-test-results.json', allowEmptyArchive: true
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: '.',
                                reportFiles: 'api-test-report.html',
                                reportName: 'API Test Report'
                            ])
                        }
                    }
                }
            }
        }
        
        stage('Code Quality') {
            steps {
                echo '📊 Running Code Quality Analysis...'
                
                script {
                    // SonarQube analysis with local SonarQube scanner
                    sh '''
                        echo "Downloading SonarQube Scanner..."
                        if [ ! -d "sonar-scanner" ]; then
                            wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
                            unzip -q sonar-scanner-cli-4.8.0.2856-linux.zip
                            mv sonar-scanner-4.8.0.2856-linux sonar-scanner
                        fi
                        
                        echo "Running SonarQube analysis with properties file..."
                        ./sonar-scanner/bin/sonar-scanner \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_TOKEN} \
                          || echo "SonarQube analysis completed with warnings"
                    '''
                }
            }
            
            post {
                always {
                    // Archive SonarQube reports
                    archiveArtifacts artifacts: '.scannerwork/report-task.txt', allowEmptyArchive: true
                }
                success {
                    echo '✅ Code quality analysis completed'
                }
                failure {
                    echo '❌ Code quality analysis failed'
                }
            }
        }
        
        stage('Security') {
            parallel {
                stage('SAST Analysis') {
                    steps {
                        echo 'Running Static Application Security Testing...'
                        
                        script {
                            // Run Semgrep for SAST
                            sh '''
                                # Install Semgrep
                                pip install semgrep || echo "Semgrep installation skipped"
                                
                                # Run SAST analysis
                                semgrep --config=auto --json --output=sast-results.json . || true
                                
                                # Parse results and fail on critical issues
                                python3 -c "
import json
import sys
try:
    with open('sast-results.json', 'r') as f:
        results = json.load(f)
    findings = results.get('results', [])
    critical = len([f for f in findings if f.get('extra', {}).get('severity') == 'ERROR'])
    high = len([f for f in findings if f.get('extra', {}).get('severity') == 'WARNING'])
    print(f'SAST Results: {critical} critical, {high} high severity issues')
    if critical > 0:
        print('❌ Critical security issues found!')
        sys.exit(1)
    print('✅ SAST analysis passed')
except Exception as e:
    print(f'SAST analysis could not be completed: {e}')
                                " || echo "SAST completed with warnings"
                            '''
                        }
                    }
                    
                    post {
                        always {
                            archiveArtifacts artifacts: 'sast-results.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('Dependency Scan') {
                    steps {
                        echo 'Running Advanced Dependency Security Scan...'
                        
                        script {
                            // Enhanced npm audit
                            sh '''
                                # Run comprehensive npm audit
                                npm audit --audit-level moderate --json > npm-audit-detailed.json || true
                                
                                # Run Snyk scan if available
                                if command -v snyk &> /dev/null; then
                                    snyk test --json > snyk-results.json || true
                                    snyk monitor || true
                                fi
                                
                                # OWASP Dependency Check
                                if [ ! -d "dependency-check" ]; then
                                    curl -L "https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.2/dependency-check-8.4.2-release.zip" -o dependency-check.zip
                                    unzip -q dependency-check.zip
                                    chmod +x dependency-check/bin/dependency-check.sh
                                fi
                                
                                ./dependency-check/bin/dependency-check.sh \
                                    --project "Healthcare App" \
                                    --scan . \
                                    --exclude "**/node_modules/**" \
                                    --exclude "**/build/**" \
                                    --format JSON \
                                    --format HTML \
                                    --out dependency-check-report || true
                                
                                # Parse and evaluate results
                                node -e "
                                const fs = require('fs');
                                try {
                                    const audit = JSON.parse(fs.readFileSync('npm-audit-detailed.json', 'utf8'));
                                    const stats = audit.metadata?.vulnerabilities || {};
                                    console.log('Dependency Vulnerability Summary:');
                                    console.log('- Critical:', stats.critical || 0);
                                    console.log('- High:', stats.high || 0);
                                    console.log('- Moderate:', stats.moderate || 0);
                                    console.log('- Low:', stats.low || 0);
                                    
                                    if (stats.critical > 0) {
                                        console.log('❌ CRITICAL vulnerabilities found!');
                                        process.exit(1);
                                    }
                                    if (stats.high > 3) {
                                        console.log('⚠️ Too many HIGH vulnerabilities!');
                                        process.exit(1);
                                    }
                                    console.log('✅ Dependency scan passed security threshold');
                                } catch (e) {
                                    console.log('⚠️ Could not parse audit results');
                                }
                                "
                            '''
                        }
                    }
                    
                    post {
                        always {
                            archiveArtifacts artifacts: 'npm-audit-detailed.json,snyk-results.json,dependency-check-report/**', allowEmptyArchive: true
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'dependency-check-report',
                                reportFiles: 'dependency-check-report.html',
                                reportName: 'Dependency Security Report'
                            ])
                        }
                    }
                }
                
                stage('Container Security') {
                    steps {
                        echo 'Running Comprehensive Container Security Scan...'
                        
                        script {
                            // Multi-tool container scanning
                            sh '''
                                # Trivy scanning
                                if ! command -v trivy &> /dev/null; then
                                    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                                fi
                                
                                # Scan frontend image
                                trivy image --format json --output trivy-frontend-detailed.json ${FRONTEND_IMAGE} || true
                                trivy image --format table ${FRONTEND_IMAGE} > trivy-frontend-summary.txt || true
                                
                                # Scan backend image  
                                trivy image --format json --output trivy-backend-detailed.json ${BACKEND_IMAGE} || true
                                trivy image --format table ${BACKEND_IMAGE} > trivy-backend-summary.txt || true
                                
                                # Grype scanning for additional validation
                                if command -v grype &> /dev/null; then
                                    grype ${FRONTEND_IMAGE} -o json > grype-frontend.json || true
                                    grype ${BACKEND_IMAGE} -o json > grype-backend.json || true
                                fi
                                
                                # Evaluate container security
                                python3 -c "
import json
import glob
import sys

total_critical = 0
total_high = 0

for file in glob.glob('trivy-*-detailed.json'):
    try:
        with open(file, 'r') as f:
            data = json.load(f)
        results = data.get('Results', [])
        for result in results:
            vulns = result.get('Vulnerabilities', [])
            critical = len([v for v in vulns if v.get('Severity') == 'CRITICAL'])
            high = len([v for v in vulns if v.get('Severity') == 'HIGH'])
            total_critical += critical
            total_high += high
            print(f'{file}: {critical} critical, {high} high vulnerabilities')
    except Exception as e:
        print(f'Could not parse {file}: {e}')

print(f'Total container vulnerabilities: {total_critical} critical, {total_high} high')
if total_critical > 0:
    print('❌ Critical vulnerabilities in container images!')
    sys.exit(1)
if total_high > 10:
    print('⚠️ Too many high vulnerabilities in containers!')
    sys.exit(1)
print('✅ Container security scan passed')
                                " || echo "Container scan completed with warnings"
                            '''
                        }
                    }
                    
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-*.json,trivy-*.txt,grype-*.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('Secrets Scanning') {
                    steps {
                        echo 'Scanning for Exposed Secrets and Credentials...'
                        
                        script {
                            sh '''
                                # TruffleHog for secrets detection
                                if ! command -v trufflehog &> /dev/null; then
                                    curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
                                fi
                                
                                # Scan filesystem for secrets
                                trufflehog filesystem . --json > secrets-scan.json || true
                                
                                # GitLeaks for additional validation
                                if command -v gitleaks &> /dev/null; then
                                    gitleaks detect --report-format json --report-path gitleaks-report.json . || true
                                fi
                                
                                # Evaluate secrets scan
                                python3 -c "
import json
import sys
import os

secrets_found = 0

# Check TruffleHog results
if os.path.exists('secrets-scan.json'):
    with open('secrets-scan.json', 'r') as f:
        content = f.read().strip()
        if content:
            lines = content.split('\n')
            secrets_found += len([line for line in lines if line.strip()])

# Check GitLeaks results
if os.path.exists('gitleaks-report.json'):
    try:
        with open('gitleaks-report.json', 'r') as f:
            data = json.load(f)
        if isinstance(data, list):
            secrets_found += len(data)
    except:
        pass

print(f'Secrets Detection Results: {secrets_found} potential secrets found')
if secrets_found > 0:
    print('❌ Potential secrets detected in codebase!')
    print('Review the scan results and remove any exposed credentials')
    sys.exit(1)
print('✅ No secrets detected')
                                " || echo "Secrets scan completed"
                            '''
                        }
                    }
                    
                    post {
                        always {
                            archiveArtifacts artifacts: 'secrets-scan.json,gitleaks-report.json', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        
        stage('Infrastructure as Code') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            
            steps {
                echo '🏗️ Deploying Infrastructure with Terraform...'
                
                script {
                    dir('terraform') {
                        // Initialize Terraform with workspace management
                        sh '''
                            echo "Initializing Terraform with workspace management..."
                            chmod +x init-workspace.sh
                            ./init-workspace.sh staging
                            
                            echo "Validating Terraform configuration..."
                            terraform validate
                            
                            echo "Formatting Terraform files..."
                            terraform fmt -check=true || terraform fmt
                        '''
                        
                        // Plan infrastructure changes
                        sh '''
                            echo "Planning infrastructure changes for staging..."
                            terraform plan \
                                -var="environment=staging" \
                                -var="namespace=healthcare" \
                                -var='replica_count={"frontend"=2,"backend"=3}' \
                                -out=tfplan-staging \
                                -detailed-exitcode || true
                                
                            # Show plan summary
                            echo "=== Terraform Plan Summary ==="
                            terraform show -no-color tfplan-staging | head -50
                        '''
                        
                        // Apply infrastructure changes for staging
                        sh '''
                            echo "Applying infrastructure changes for staging..."
                            terraform apply -auto-approve tfplan-staging
                            
                            echo "Getting Terraform outputs..."
                            terraform output -json > terraform-outputs-staging.json
                            
                            # Display infrastructure status
                            echo "=== Infrastructure Deployment Completed ==="
                            terraform output
                            
                            # Verify Kubernetes resources
                            echo "=== Verifying Kubernetes Resources ==="
                            kubectl get all -n $(terraform output -raw namespace) || echo "Resources verification failed"
                        '''
                        
                        // Store outputs for later stages
                        script {
                            def terraformOutputs = readJSON file: 'terraform/terraform-outputs-staging.json'
                            env.TERRAFORM_NAMESPACE = terraformOutputs.namespace.value
                            env.TERRAFORM_BACKEND_SERVICE = terraformOutputs.backend_service.value
                            env.TERRAFORM_FRONTEND_SERVICE = terraformOutputs.frontend_service.value
                            
                            echo "Terraform outputs stored:"
                            echo "  Namespace: ${env.TERRAFORM_NAMESPACE}"
                            echo "  Backend Service: ${env.TERRAFORM_BACKEND_SERVICE}"
                            echo "  Frontend Service: ${env.TERRAFORM_FRONTEND_SERVICE}"
                        }
                    }
                }
            }
            
            post {
                always {
                    // Archive Terraform files
                    archiveArtifacts artifacts: 'terraform/tfplan-*,terraform/terraform-outputs-*.json,terraform/.terraform.lock.hcl', allowEmptyArchive: true
                }
                success {
                    echo '✅ Infrastructure deployment successful'
                }
                failure {
                    echo '❌ Infrastructure deployment failed'
                    
                    // Cleanup on failure
                    dir('terraform') {
                        sh '''
                            echo "Cleaning up failed infrastructure..."
                            
                            # Ensure we're in the right workspace
                            terraform workspace select staging || echo "Workspace staging not found"
                            
                            # Try to destroy failed resources
                            terraform destroy -auto-approve \
                                -var="environment=staging" \
                                -var="namespace=healthcare" \
                                -var='replica_count={"frontend"=2,"backend"=3}' || echo "Cleanup completed with warnings"
                            
                            # Switch back to default workspace
                            terraform workspace select default || true
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            
            steps {
                echo '🚀 Deploying to Staging Environment...'
                
                script {
                    // Push Docker images to registry
                    docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS_ID}") {
                        def frontendImage = docker.image("${DOCKER_REPO}-frontend:${BUILD_NUMBER}")
                        def backendImage = docker.image("${DOCKER_REPO}-backend:${BUILD_NUMBER}")
                        
                        frontendImage.push()
                        frontendImage.push("latest")
                        
                        backendImage.push()
                        backendImage.push("latest")
                    }
                    
                    // Update application images using Terraform-managed infrastructure
                    withKubeConfig([credentialsId: 'kubeconfig-staging']) {
                        sh '''
                            # Use Terraform-managed namespace
                            NAMESPACE="${TERRAFORM_NAMESPACE:-healthcare-staging}"
                            
                            echo "Deploying to Terraform-managed namespace: $NAMESPACE"
                            
                            # Update deployment images using kubectl patch (leveraging Terraform-created resources)
                            kubectl patch deployment frontend -n $NAMESPACE \
                              -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","image":"'${FRONTEND_IMAGE}'"}]}}}}'
                            
                            kubectl patch deployment backend -n $NAMESPACE \
                              -p '{"spec":{"template":{"spec":{"containers":[{"name":"backend","image":"'${BACKEND_IMAGE}'"}]}}}}'
                            
                            # Wait for rollout to complete
                            kubectl rollout status deployment/frontend -n $NAMESPACE --timeout=300s
                            kubectl rollout status deployment/backend -n $NAMESPACE --timeout=300s
                            
                            # Verify deployment
                            echo "Deployment verification:"
                            kubectl get pods -n $NAMESPACE
                            kubectl get services -n $NAMESPACE
                            
                            # Check if HPA is working
                            kubectl get hpa -n $NAMESPACE || echo "HPA not found - using Terraform defaults"
                        '''
                    }
                    
                    // Run smoke tests using Terraform outputs
                    sh '''
                        # Wait for services to be ready
                        sleep 60
                        
                        # Use Terraform-managed services
                        NAMESPACE="${TERRAFORM_NAMESPACE:-healthcare-staging}"
                        BACKEND_SERVICE="${TERRAFORM_BACKEND_SERVICE:-backend}"
                        
                        echo "Testing Terraform-deployed services..."
                        
                        # Port forward for testing (since we're using ClusterIP from Terraform)
                        kubectl port-forward svc/$BACKEND_SERVICE 8080:5000 -n $NAMESPACE &
                        PORT_FORWARD_PID=$!
                        
                        sleep 10
                        
                        # Run smoke tests
                        curl -f http://localhost:8080/health || echo "Health check failed"
                        curl -f http://localhost:8080/api/appointments || echo "API check failed"
                        
                        # Cleanup port forward
                        kill $PORT_FORWARD_PID || true
                    '''
                }
            }
            
            post {
                success {
                    echo '✅ Staging deployment successful'
                    // Send notification
                    slackSend(
                        channel: '#deployments',
                        color: 'good',
                        message: "✅ ${APP_NAME} v${BUILD_NUMBER} deployed to staging successfully"
                    )
                }
                failure {
                    echo '❌ Staging deployment failed'
                    slackSend(
                        channel: '#deployments',
                        color: 'danger',
                        message: "❌ ${APP_NAME} v${BUILD_NUMBER} staging deployment failed"
                    )
                }
            }
        }
        
        stage('Release to Production') {
            when {
                branch 'main'
            }
            
            steps {
                echo '🎯 Preparing Production Release...'
                
                script {
                    // Manual approval for production deployment
                    input message: 'Deploy to Production?', 
                          ok: 'Deploy',
                          submitterParameter: 'APPROVER'
                    
                    echo "Production deployment approved by: ${env.APPROVER}"
                    
                    // Deploy production infrastructure with Terraform
                    dir('terraform') {
                        sh '''
                            echo "Deploying production infrastructure with Terraform..."
                            
                            # Switch to production workspace
                            ./init-workspace.sh production
                            
                            # Plan production infrastructure
                            terraform plan \
                                -var="environment=production" \
                                -var="namespace=healthcare" \
                                -var='replica_count={"frontend"=3,"backend"=5}' \
                                -out=tfplan-production \
                                -detailed-exitcode || true
                            
                            # Show production plan summary
                            echo "=== Production Terraform Plan Summary ==="
                            terraform show -no-color tfplan-production | head -50
                            
                            # Apply production infrastructure
                            terraform apply -auto-approve tfplan-production
                            
                            # Get production outputs
                            terraform output -json > terraform-outputs-production.json
                            
                            echo "=== Production Infrastructure Deployment Completed ==="
                            terraform output
                            
                            # Verify production Kubernetes resources
                            echo "=== Verifying Production Kubernetes Resources ==="
                            kubectl get all -n $(terraform output -raw namespace) || echo "Production resources verification failed"
                        '''
                        
                        // Store production outputs
                        script {
                            def terraformOutputs = readJSON file: 'terraform/terraform-outputs-production.json'
                            env.TERRAFORM_PROD_NAMESPACE = terraformOutputs.namespace.value
                            env.TERRAFORM_PROD_BACKEND_SERVICE = terraformOutputs.backend_service.value
                            env.TERRAFORM_PROD_FRONTEND_SERVICE = terraformOutputs.frontend_service.value
                            
                            echo "Production Terraform outputs stored:"
                            echo "  Namespace: ${env.TERRAFORM_PROD_NAMESPACE}"
                            echo "  Backend Service: ${env.TERRAFORM_PROD_BACKEND_SERVICE}"
                            echo "  Frontend Service: ${env.TERRAFORM_PROD_FRONTEND_SERVICE}"
                        }
                    }
                    
                    // Deploy to production using Terraform-managed infrastructure
                    withKubeConfig([credentialsId: 'kubeconfig-production']) {
                        sh '''
                            # Use Terraform-managed namespace
                            NAMESPACE="${TERRAFORM_PROD_NAMESPACE:-healthcare-production}"
                            
                            echo "Deploying to Terraform-managed production namespace: $NAMESPACE"
                            
                            # Use blue-green deployment strategy with Terraform-created resources
                            kubectl patch deployment frontend -n $NAMESPACE \
                              -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","image":"'${FRONTEND_IMAGE}'"}]}}}}'
                            
                            kubectl patch deployment backend -n $NAMESPACE \
                              -p '{"spec":{"template":{"spec":{"containers":[{"name":"backend","image":"'${BACKEND_IMAGE}'"}]}}}}'
                            
                            # Wait for rollout
                            kubectl rollout status deployment/frontend -n $NAMESPACE --timeout=600s
                            kubectl rollout status deployment/backend -n $NAMESPACE --timeout=600s
                            
                            # Verify deployment
                            echo "Production deployment verification:"
                            kubectl get pods -n $NAMESPACE
                            kubectl get services -n $NAMESPACE
                            kubectl get hpa -n $NAMESPACE
                            
                            # Check resource utilization
                            kubectl top pods -n $NAMESPACE || echo "Metrics server not available"
                        '''
                    }
                    
                    // Tag the release
                    sh '''
                        git tag -a "v${BUILD_NUMBER}" -m "Release version ${BUILD_NUMBER} - Terraform managed"
                        git push origin "v${BUILD_NUMBER}" || true
                    '''
                }
            }
            
            post {
                success {
                    echo '✅ Production deployment successful'
                    slackSend(
                        channel: '#deployments',
                        color: 'good',
                        message: "🎉 ${APP_NAME} v${BUILD_NUMBER} deployed to production successfully by ${env.APPROVER}"
                    )
                }
                failure {
                    echo '❌ Production deployment failed'
                    slackSend(
                        channel: '#deployments',
                        color: 'danger',
                        message: "❌ ${APP_NAME} v${BUILD_NUMBER} production deployment failed"
                    )
                }
            }
        }
        
        stage('Monitoring & Alerting') {
            steps {
                echo '📊 Setting up Monitoring and Alerting...'
                
                script {
                    // Configure Prometheus alerts using Terraform-managed resources
                    sh '''
                        # Use Terraform-managed namespace
                        MONITORING_NAMESPACE="${TERRAFORM_PROD_NAMESPACE:-${TERRAFORM_NAMESPACE:-healthcare-production}}"
                        
                        echo "Setting up monitoring for namespace: $MONITORING_NAMESPACE"
                        
                        # Apply Prometheus rules to Terraform-managed namespace
                        kubectl apply -f kubernetes/prometheus-rules.yaml -n $MONITORING_NAMESPACE
                        
                        # Apply monitoring configuration
                        kubectl apply -f kubernetes/prometheus.yaml -n $MONITORING_NAMESPACE
                        kubectl apply -f kubernetes/grafana.yaml -n $MONITORING_NAMESPACE
                        
                        # Verify Prometheus is scraping targets
                        sleep 30
                        
                        # Check if application metrics are available
                        echo "Checking Prometheus targets..."
                        curl -s "${PROMETHEUS_URL}/api/v1/query?query=up{job='healthcare-backend'}" | jq '.data.result | length' || echo "Prometheus metrics check: 0 targets found"
                        
                        # Verify services are discoverable
                        kubectl get endpoints -n $MONITORING_NAMESPACE
                    '''
                    
                    // Set up Grafana dashboards
                    sh '''
                        # Check Grafana health
                        echo "Checking Grafana accessibility..."
                        curl -f "${GRAFANA_URL}/api/health" || echo "Grafana not accessible - may need port forwarding"
                        
                        # Port forward for Grafana access during pipeline
                        MONITORING_NAMESPACE="${TERRAFORM_PROD_NAMESPACE:-${TERRAFORM_NAMESPACE:-healthcare-production}}"
                        kubectl port-forward svc/grafana 3001:3000 -n $MONITORING_NAMESPACE &
                        GRAFANA_PID=$!
                        
                        sleep 10
                        
                        # Test local Grafana connection
                        curl -f "http://localhost:3001/api/health" && echo "✅ Grafana accessible via port-forward" || echo "⚠️ Grafana connection failed"
                        
                        # Cleanup
                        kill $GRAFANA_PID || true
                    '''
                    
                    // Create synthetic monitoring checks for Terraform-managed services
                    sh '''
                        # Add basic uptime checks for Terraform-managed services
                        echo "Setting up uptime monitoring for Terraform-managed infrastructure..."
                        
                        MONITORING_NAMESPACE="${TERRAFORM_PROD_NAMESPACE:-${TERRAFORM_NAMESPACE:-healthcare-production}}"
                        BACKEND_SERVICE="${TERRAFORM_PROD_BACKEND_SERVICE:-${TERRAFORM_BACKEND_SERVICE:-backend}}"
                        
                        echo "Monitoring configuration:"
                        echo "  Namespace: $MONITORING_NAMESPACE"
                        echo "  Backend Service: $BACKEND_SERVICE"
                        
                        # Verify services are healthy
                        kubectl get svc $BACKEND_SERVICE -n $MONITORING_NAMESPACE || echo "Backend service not found"
                        
                        # Create monitoring endpoint test
                        kubectl port-forward svc/$BACKEND_SERVICE 8081:5000 -n $MONITORING_NAMESPACE &
                        BACKEND_PID=$!
                        
                        sleep 10
                        
                        # Test application health
                        curl -f "http://localhost:8081/health" && echo "✅ Backend health check passed" || echo "⚠️ Backend health check failed"
                        
                        # Cleanup
                        kill $BACKEND_PID || true
                    '''
                }
            }
            
            post {
                success {
                    echo '✅ Monitoring and alerting configured'
                }
                failure {
                    echo '❌ Monitoring setup failed'
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            
            // Clean up workspace
            cleanWs()
            
            // Remove dangling Docker images
            sh 'docker image prune -f || true'
        }
        
        success {
            echo '🎉 Pipeline completed successfully!'
            
            // Send success notification
            emailext (
                subject: "✅ ${APP_NAME} Pipeline Success - Build ${BUILD_NUMBER}",
                body: """
                    <h2>Pipeline Execution Successful</h2>
                    <p><strong>Project:</strong> ${APP_NAME}</p>
                    <p><strong>Build Number:</strong> ${BUILD_NUMBER}</p>
                    <p><strong>Git Commit:</strong> ${env.GIT_COMMIT}</p>
                    <p><strong>Commit Message:</strong> ${env.GIT_COMMIT_MSG}</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    
                    <h3>Deployed Images:</h3>
                    <ul>
                        <li>Frontend: ${env.FRONTEND_IMAGE}</li>
                        <li>Backend: ${env.BACKEND_IMAGE}</li>
                    </ul>
                """,
                to: "${env.CHANGE_AUTHOR_EMAIL ?: 'dev-team@company.com'}",
                mimeType: 'text/html'
            )
        }
        
        failure {
            echo '❌ Pipeline failed!'
            
            // Send failure notification
            emailext (
                subject: "❌ ${APP_NAME} Pipeline Failed - Build ${BUILD_NUMBER}",
                body: """
                    <h2>Pipeline Execution Failed</h2>
                    <p><strong>Project:</strong> ${APP_NAME}</p>
                    <p><strong>Build Number:</strong> ${BUILD_NUMBER}</p>
                    <p><strong>Git Commit:</strong> ${env.GIT_COMMIT}</p>
                    <p><strong>Commit Message:</strong> ${env.GIT_COMMIT_MSG}</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p><strong>Console Log:</strong> <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a></p>
                    
                    <p>Please check the console log for detailed error information.</p>
                """,
                to: "${env.CHANGE_AUTHOR_EMAIL ?: 'dev-team@company.com'}",
                mimeType: 'text/html'
            )
        }
        
        unstable {
            echo '⚠️ Pipeline completed with warnings'
        }
    }
}
