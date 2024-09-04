pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: jenkins-agent
                image: denisber1984/jenkins-agent:helm-docker
                securityContext:
                  privileged: true
                command:
                - cat
                tty: true
                volumeMounts:
                - mountPath: /var/run/docker.sock
                  name: docker-sock
                - mountPath: /home/jenkins/agent
                  name: workspace-volume
              volumes:
              - hostPath:
                  path: /var/run/docker.sock
                name: docker-sock
              - emptyDir:
                  medium: ""
                name: workspace-volume
            """
        }
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Verify Files') {
            steps {
                sh 'ls -R ./my-polybot-app-chart'
            }
        }

        stage('Build Docker Image') {
            steps {
                container('jenkins-agent') {   // Ensure Docker commands run in the correct container
                    script {
                        echo "Checking Docker installation"
                        sh 'docker --version || echo "Docker command failed"'

                        echo "Building Docker Image"
                        def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        sh "docker build -t denisber1984/mypolybot:${commitHash} ."
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                container('jenkins-agent') {   // Ensure Docker push runs in the correct container
                    script {
                        def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        withCredentials([string(credentialsId: 'dockerhub', variable: 'DOCKER_HUB_CREDENTIALS')]) {
                            sh "echo ${DOCKER_HUB_CREDENTIALS} | docker login -u denisber1984 --password-stdin"
                        }
                        sh "docker push denisber1984/mypolybot:${commitHash}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('jenkins-agent') {   // Ensure Kubernetes deployment runs in the jenkins-agent container with helm
                    withEnv(["KUBECONFIG=${env.WORKSPACE}/.kube/config"]) {
                        sh 'helm upgrade --install my-polybot-app ./my-polybot-app-chart --namespace demoapp'
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
