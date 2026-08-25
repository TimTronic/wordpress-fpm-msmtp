pipeline {
    agent any

    environment {
        TARGET_REPO = 'https://docker-registry.deadlyninja.com'
        TARGET_REPO_CREDENTIALS = 'DeadlyNinja'
        DOCKER_IMAGE_NAME = 'deadlyninja/wordpress-fpm-msmtp'
        DOCKERFILE_PATH = './Dockerfile'
    }

    triggers {
        pollSCM('H/15 * * * *')
        // The build is `--pull` and the Dockerfile ends in `apt-get dist-upgrade`, so a
        // rebuild picks up a new base image and new Debian packages. On pollSCM alone that
        // only ever happened when someone committed - and in 2026 the upstream
        // `wordpress:6-php8.4-fpm` tag stopped being rebuilt without anyone noticing, so
        // the published image sat on a three-month-old PHP. Build nightly regardless.
        cron('H 3 * * *')
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
