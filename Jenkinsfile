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
                env:
                - name: PATH
                  value: "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin"
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
                    echo "Building Docker Image"
                    sh 'which docker || echo "Docker not found in PATH"'
                    sh 'ls -l /usr/local/bin/ | grep docker || echo "Docker binary not in /usr/local/bin"'
                    sh 'alias docker=/usr/local/bin/docker'
                    sh 'export PATH=$PATH:/usr/local/bin && docker --version || true'
                    sh 'echo $PATH'
                    def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    sh 'export PATH=$PATH:/usr/local/bin && docker build -t denisber1984/mypolybot:${commitHash} .'
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
                    sh "export PATH=\$PATH:/usr/local/bin && docker push denisber1984/mypolybot:${commitHash}"
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
