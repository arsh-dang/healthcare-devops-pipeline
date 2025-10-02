pipeline {
    agent any
    
    stages {
        stage('Test Datadog Keys') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'datadog-api-key', variable: 'DATADOG_API_KEY'),
                        string(credentialsId: 'datadog-app-key', variable: 'DATADOG_APP_KEY')
                    ]) {
                        sh './test-jenkins-datadog-keys.sh'
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Datadog key testing completed'
        }
    }
}
