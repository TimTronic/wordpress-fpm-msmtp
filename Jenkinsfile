pipeline {
    agent any

    environment {
        TARGET_REPO = 'https://docker-registry.deadlyninja.com'
        TARGET_REPO_CREDENTIALS = 'DeadlyNinja'
        DOCKER_IMAGE_NAME = 'deadlyninja/wordpress-fpm-msmtp-civicrm'
        DOCKERFILE_PATH = './Dockerfile'
    }

    triggers {
        pollSCM('H/15 * * * *')
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
                    docker.build(env.DOCKER_IMAGE_NAME, '--pull -f ' + env.DOCKERFILE_PATH + ' .')
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry(env.TARGET_REPO, env.TARGET_REPO_CREDENTIALS) {
                        docker.image(env.DOCKER_IMAGE_NAME).push('latest')
                    }
                }
            }
        }
    }
}
