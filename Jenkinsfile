pipeline {
    parameters {
        choice(name: 'AGENT_TYPE', choices: ['kubernetes', 'ec2'], description: 'Choose the type of agent to run the job')
    }

    // Dynamically set agent based on the parameter
    agent {
        label AGENT_TYPE == 'ec2' ? 'ec2-fleet' : ''
    }

    environment {
        KUBECONFIG = "${env.WORKSPACE}/.kube/config"
    }

    stages {
        stage('Select Agent') {
            when {
                expression { params.AGENT_TYPE == 'kubernetes' }
            }
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
            steps {
                echo "Using Kubernetes Agent"
            }
        }

        stage('Checkout SCM') {
            steps {
                checkout scm
                sh 'ls -la'  // List the files in the workspace to ensure everything is checked out
            }
        }

        stage('Install Python Requirements') {
            steps {
                script {
                    if (params.AGENT_TYPE == 'kubernetes') {
                        container('jenkins-agent') {
                            sh """
                                python3 -m venv venv
                                . venv/bin/activate
                                pip install pytest unittest2 pylint flask telebot Pillow loguru matplotlib
                            """
                        }
                    } else {
                        sh """
                            python3 -m venv venv
                            . venv/bin/activate
                            pip install pytest unittest2 pylint flask telebot Pillow loguru matplotlib
                        """
                    }
                }
            }
        }

        stage('Unittest') {
            steps {
                script {
                    if (params.AGENT_TYPE == 'kubernetes') {
                        container('jenkins-agent') {
                            sh """
                                python3 -m venv venv
                                . venv/bin/activate
                                python -m pytest --junitxml results.xml polybot/test
                            """
                        }
                    } else {
                        sh """
                            python3 -m venv venv
                            . venv/bin/activate
                            python -m pytest --junitxml results.xml polybot/test
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    if (params.AGENT_TYPE == 'kubernetes') {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                            def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                            sh "docker build -t denisber1984/mypolybot:${commitHash} polybot/"
                            sh "echo ${PASS} | docker login -u ${USER} --password-stdin"
                            sh "docker push denisber1984/mypolybot:${commitHash}"
                        }
                    } else if (params.AGENT_TYPE == 'ec2') {
                        def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        def ecrRepo = "023196572641.dkr.ecr.us-east-2.amazonaws.com/denber1984/app-repo"
                        withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials' ]]) {
                            sh "aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${ecrRepo}"
                            sh "docker build -t ${ecrRepo}:${commitHash} polybot/"
                            sh "docker push ${ecrRepo}:${commitHash}"
                        }
                    }
                }
            }
        }

        stage('Helm Deployment') {
            steps {
                script {
                    if (params.AGENT_TYPE == 'kubernetes') {
                        container('jenkins-agent') {
                            withEnv(["KUBECONFIG=${env.KUBECONFIG}"]) {
                                sh 'helm upgrade --install my-polybot-app ./my-polybot-app-chart --namespace demoapp'
                            }
                        }
                    } else {
                        withEnv(["KUBECONFIG=${env.WORKSPACE}/.kube/config"]) {
                            sh 'helm upgrade --install my-polybot-app ./my-polybot-app-chart --namespace demoapp'
                        }
                    }
                }
            }
        }

        stage('Create/Update ArgoCD Application') {
            steps {
                script {
                    if (params.AGENT_TYPE == 'kubernetes') {
                        container('jenkins-agent') {
                            sh 'kubectl apply -f argocd-config/application.yaml -n argocd'
                        }
                    } else {
                        sh 'kubectl apply -f argocd-config/application.yaml -n argocd'
                    }
                }
            }
        }

        stage('Sync ArgoCD Application') {
            steps {
                script {
                    if (params.AGENT_TYPE == 'kubernetes') {
                        container('jenkins-agent') {
                            sh 'kubectl -n argocd patch application my-polybot-app --type merge -p \'{"metadata": {"annotations": {"argocd.argoproj.io/sync-wave": "-1"}}}\''
                        }
                    } else {
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
