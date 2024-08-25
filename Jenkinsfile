@Library('jenkins-shared-library') _

pipeline {
    agent {
        kubernetes {
            yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: jenkins-agent
                image: denisber1984/jenkins-agent:latest
                command:
                - cat
                tty: true
            '''
        }
    }

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub')
        DOCKER_IMAGE = 'denisber1984/mypolybot:polybot-image-v1'
        KUBECONFIG_CREDENTIAL_ID = 'kubeconfig'
    }

    stages {
        stage('Say Hello') {
            steps {
                script {
                    myLib.sayHello('Den')
                }
            }
        }

        stage('Checkout SCM') {
            steps {
                checkout scm
                script {
                    sh 'git config --global --add safe.directory /var/lib/jenkins/workspace/mypolybot-pipeline'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def commitId = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    myLib.buildDockerImage(DOCKER_IMAGE, commitId, env.BUILD_NUMBER)
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def commitId = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    docker.withRegistry('', DOCKER_HUB_CREDENTIALS) {
                        sh "docker push ${DOCKER_IMAGE}:${commitId}-${env.BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    withCredentials([file(credentialsId: KUBECONFIG_CREDENTIAL_ID, variable: 'KUBECONFIG')]) {
                        sh 'kubectl apply -f polybot/app-deployment.yaml -n demoapp'
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            script {
                if (fileExists("${WORKSPACE}/results.xml")) {
                    junit allowEmptyResults: true, testResults: '**/results.xml'
                }
            }
        }
    }
}
