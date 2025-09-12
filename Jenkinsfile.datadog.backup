pipeline {
    agent any

    environment {
        TERRAFORM_STRATEGY = 'clean'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }

    parameters {
        string(name: 'ENVIRONMENT', defaultValue: 'staging', description: 'Target environment')
        string(name: 'FRONTEND_IMAGE_TAG', defaultValue: "${env.BUILD_NUMBER}", description: 'Frontend image tag')
        string(name: 'BACKEND_IMAGE_TAG', defaultValue: "${env.BUILD_NUMBER}", description: 'Backend image tag')
        booleanParam(name: 'ENABLE_DATADOG', defaultValue: true, description: 'Enable Datadog monitoring')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Datadog Credentials') {
            steps {
                script {
                    // Use Jenkins global credential for Datadog API key
                    withCredentials([string(credentialsId: 'datadog-api-key', variable: 'DD_API_KEY')]) {
                        env.DATADOG_API_KEY = DD_API_KEY
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    // Build backend image
                    sh """
                        cd server
                        docker build -t healthcare-app-backend:${params.BACKEND_IMAGE_TAG} .
                    """

                    // Build frontend image
                    sh """
                        docker build -f Dockerfile.frontend -t healthcare-app-frontend:${params.FRONTEND_IMAGE_TAG} .
                    """
                }
            }
        }

        stage('Deploy Infrastructure') {
            steps {
                script {
                    dir('terraform') {
                        sh """
                            chmod +x deploy.sh
                            ./deploy.sh deploy \\
                                ${params.ENVIRONMENT} \\
                                ${env.BUILD_NUMBER} \\
                                healthcare-app-frontend:${params.FRONTEND_IMAGE_TAG} \\
                                healthcare-app-backend:${params.BACKEND_IMAGE_TAG} \\
                                "${env.DATADOG_API_KEY}" \\
                                ${params.ENABLE_DATADOG}
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    // Verify pods are running
                    sh """
                        kubectl get pods -n healthcare-${params.ENVIRONMENT}
                        kubectl get pods -n monitoring-${params.ENVIRONMENT}
                    """

                    // Check Datadog if enabled
                    if (params.ENABLE_DATADOG) {
                        sh """
                            helm list -n healthcare-${params.ENVIRONMENT}
                            kubectl get pods -n healthcare-${params.ENVIRONMENT} | grep datadog
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment completed successfully with Datadog monitoring!'
        }
        failure {
            echo 'Deployment failed!'
            // Optional: cleanup on failure
            script {
                dir('terraform') {
                    sh './deploy.sh clean || true'
                }
            }
        }
    }
}
