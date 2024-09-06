pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              serviceAccountName: jenkins-admin  # Ensure Jenkins is using the correct service account
              containers:
              - name: jenkins-agent
                image: denisber1984/jenkins-agent:helm-kubectl
                securityContext:
                  privileged: true
                  runAsUser: 0
                command:
                - sh
                - -c
                - |
                  git config --global --add safe.directory /home/jenkins/agent/workspace/kubernetes-project-pipeline
                  cat
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

    environment {
        KUBECONFIG = "${env.WORKSPACE}/.kube/config"  // Add KUBECONFIG environment variable
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
                sh 'ls -la'  // Verify workspace after checkout
            }
        }

        stage('Verify Workspace') {  // New stage to verify the workspace
            steps {
                sh 'pwd'  // Print current directory
                sh 'ls -la ./my-polybot-app-chart'  // List contents of my-polybot-app-chart
                sh 'cat ./my-polybot-app-chart/Chart.yaml'  // Show Chart.yaml content
            }
        }

        stage('Build Docker Image') {
            steps {
                container('jenkins-agent') {
                    script {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                            sh 'docker --version || echo "Docker command failed"'
                            def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                            sh "docker build -t denisber1984/mypolybot:${commitHash} polybot/"
                        }
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                container('jenkins-agent') {
                    script {
                        def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                            sh "echo ${PASS} | docker login -u ${USER} --password-stdin"
                            sh "docker push denisber1984/mypolybot:${commitHash}"
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('jenkins-agent') {
                    script {
                        withEnv(["KUBECONFIG=${env.KUBECONFIG}"]) {
                            sh 'helm version'
                            sh 'kubectl get nodes'
                            sh 'ls -R ./my-polybot-app-chart'  // Verify files
                            sh 'cat ./my-polybot-app-chart/Chart.yaml'  // Ensure Chart.yaml exists
                            sh 'helm upgrade --install my-polybot-app ./my-polybot-app-chart --namespace demoapp -f ./my-polybot-app-chart/values.yaml'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()  // Ensure workspace is cleaned up at the end
        }
    }
}
