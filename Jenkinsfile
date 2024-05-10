pipeline {
    agent any
    
    environment {
        // TARGET_REPO = 
        // TARGET_REPO_CREDENTIALS = 
        DOCKER_IMAGE_NAME = 'deadlyninja/wordpress-fpm-msmtp'
        DOCKERFILE_PATH = './Dockerfile'
    }
   
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build(env.DOCKER_IMAGE_NAME, '-f ' + env.DOCKERFILE_PATH + ' .')
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry(env.TARGET_REPO,, env.TARGET_REPO_CREDENTIALS) {
                        docker.image(env.DOCKER_IMAGE_NAME).push('latest')
                    }
                }
            }
        }
    }
}
