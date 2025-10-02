pipeline {
    agent any
    
    stages {
        stage('Test Datadog App Key') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'datadog-app-key', variable: 'DATADOG_APP_KEY')
                    ]) {
                        sh './test-datadog-app-key.sh "$DATADOG_APP_KEY"'
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Datadog App Key testing completed'
        }
    }
}
