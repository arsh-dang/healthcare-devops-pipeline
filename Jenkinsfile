// Force Jenkins to reload pipeline - add this at the very top of Jenkinsfile
def forcePipelineReload = true

node {
    try {
        // Environment variables setup
        env.DOCKER_REGISTRY = 'docker.io'
        env.DOCKER_REPO = 'yourusername/healthcare-app'
        env.APP_NAME = 'healthcare-app'
        env.NAMESPACE = 'healthcare-staging'
        env.TF_ENVIRONMENT = 'staging'
        env.ENABLE_PERSISTENT_STORAGE = 'true'

        // Datadog configuration
        env.DD_ENV = 'staging'
        env.DD_SERVICE = 'healthcare-app'
        env.DD_VERSION = "${BUILD_NUMBER}"
        env.DD_TAGS = "env:${env.DD_ENV},service:${env.DD_SERVICE},version:${env.DD_VERSION},pipeline:jenkins"

        // Configure tool paths for macOS environment
        env.PATH = "${env.PATH}:/usr/local/bin:/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin"

        // Enable timestamps for all output
        timestamps {

            stage('Force Pipeline Reload Check') {
                echo '🔄 Checking if pipeline reload is needed...'
                echo "Pipeline reload flag: ${forcePipelineReload}"
                echo "Current pipeline type: Scripted (no parameters required)"
            }
