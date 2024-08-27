pipeline {
    agent {
        kubernetes {
            yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: jenkins-agent
                image: denisber1984/jenkins-agent:docker
                command:
                - cat
                tty: true
                securityContext:
                  runAsUser: 0
                volumeMounts:
                - name: docker-sock
                  mountPath: /var/run/docker.sock
                - mountPath: /home/jenkins/agent
                  name: workspace-volume
                  readOnly: false
              volumes:
                - name: docker-sock
                  hostPath:
                    path: /var/run/docker.sock
                - name: workspace-volume
                  emptyDir: {}
            '''
        }
    }

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub')
        DOCKER_IMAGE = 'denisber1984/mypolybot'
        KUBECONFIG_CREDENTIAL_ID = 'kubeconfig'
    }

    options {
        buildDiscarder(logRotator(daysToKeepStr: '30'))
        disableConcurrentBuilds()
        timestamps()
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

        stage('Build Docker Image') {
            steps {
                container('jenkins-agent') {
                    script {
                        sh 'git config --global --add safe.directory /home/jenkins/agent/workspace/kubernetes-project-pipeline'
                        def commitId = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                        sh "docker build -t denisber1984/mypolybot:${commitId}-${env.BUILD_NUMBER} jenkins-agent"
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                container('jenkins-agent') {
                    script {
                        def commitId = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                        sh "docker push ${DOCKER_IMAGE}:${commitId}-${env.BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('jenkins-agent') {
                    withKubeConfig([credentialsId: KUBECONFIG_CREDENTIAL_ID, namespace: 'demoapp']) {
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
