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
                script {
                    sh 'git config --global --add safe.directory /var/lib/jenkins/workspace/kubernetes-project-pipeline'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('jenkins-agent') { // Ensure the commands are executed in the correct container
                    script {
                        def commitId = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                        sh "docker build -t ${DOCKER_IMAGE}:${commitId}-${env.BUILD_NUMBER} ."
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                container('jenkins-agent') { // Ensure the commands are executed in the correct container
                    script {
                        def commitId = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                        sh "docker push ${DOCKER_IMAGE}:${commitId}-${env.BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('jenkins-agent') { // Ensure the commands are executed in the correct container
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
