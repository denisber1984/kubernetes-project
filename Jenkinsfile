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
        stage('Say Hello') {
            steps {
                echo 'Hello, Den'
            }
        }

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
                script {
                    // Print Docker version and PATH to confirm environment
                    sh 'docker --version'
                    sh 'echo $PATH'

                    def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    sh "docker build -t denisber1984/mypolybot:${commitHash} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    withCredentials([string(credentialsId: 'dockerhub', variable: 'DOCKER_HUB_CREDENTIALS')]) {
                        sh "echo ${DOCKER_HUB_CREDENTIALS} | docker login -u denisber1984 --password-stdin"
                    }
                    sh "docker push denisber1984/mypolybot:${commitHash}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('jnlp') {
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
