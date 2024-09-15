pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              serviceAccountName: jenkins-admin
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
        KUBECONFIG = "${env.WORKSPACE}/.kube/config"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
                sh 'ls -la'  // List the files in the workspace to ensure everything is checked out
            }
        }

        stage('Install Python Requirements') {
            steps {
                container('jenkins-agent') {
                    // Install Python dependencies
                    sh """
                        python3 -m venv venv
                        . venv/bin/activate
                        pip install pytest unittest2 pylint flask telebot Pillow loguru matplotlib
                    """
                }
            }
        }

        stage('Unittest') {
            steps {
                container('jenkins-agent') {
                    // Run unittests
                    sh """
                        python3 -m venv venv
                        . venv/bin/activate
                        python -m pytest --junitxml results.xml polybot/test
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('jenkins-agent') {
                    script {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                            def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                            sh "docker build -t denisber1984/mypolybot:${commitHash} polybot/"
                            sh "echo ${PASS} | docker login -u ${USER} --password-stdin"
                            sh "docker push denisber1984/mypolybot:${commitHash}"
                        }
                    }
                }
            }
        }

        stage('Helm Deployment') {
            steps {
                container('jenkins-agent') {
                    script {
                        withEnv(["KUBECONFIG=${env.KUBECONFIG}"]) {
                            sh 'helm upgrade --install my-polybot-app ./my-polybot-app-chart --namespace demoapp'
                        }
                    }
                }
            }
        }

        stage('Create/Update ArgoCD Application') {
            steps {
                container('jenkins-agent') {
                    script {
                        sh 'kubectl apply -f argocd-config/application.yaml -n argocd'
                    }
                }
            }
        }

        stage('Sync ArgoCD Application') {
            steps {
                container('jenkins-agent') {
                    script {
                        sh 'kubectl -n argocd patch application my-polybot-app --type merge -p \'{"metadata": {"annotations": {"argocd.argoproj.io/sync-wave": "-1"}}}\''
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
