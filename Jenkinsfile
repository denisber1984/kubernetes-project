pipeline {
    parameters {
        choice(name: 'AGENT_TYPE', choices: ['kubernetes', 'ec2'], description: 'Choose the type of agent to run the job')
    }

    agent {
        label AGENT_TYPE == 'ec2' ? 'ec2-fleet' : ''
    }

    environment {
        ECR_REPOSITORY = "023196572641.dkr.ecr.us-east-2.amazonaws.com/denber1984/app-repo"
        AWS_REGION = 'us-east-2'
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
                        image: denisber1984/jenkins-agent:aws-k8s-agent
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
                sh 'ls -la'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    if (params.AGENT_TYPE == 'kubernetes') {
                        container('jenkins-agent') {
                            withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                                sh "docker build -t denisber1984/mypolybot:${commitHash} polybot/"
                                sh "echo ${PASS} | docker login -u ${USER} --password-stdin"
                                sh "docker push denisber1984/mypolybot:${commitHash}"
                            }
                        }
                    } else if (params.AGENT_TYPE == 'ec2') {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                            sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
                            sh "docker build -t ${ECR_REPOSITORY}:${commitHash} polybot/"
                            sh "docker push ${ECR_REPOSITORY}:${commitHash}"
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
                                sh 'helm upgrade --install my-polybot-app ./my-polybot-app-chart --namespace den-pollyapp'
                            }
                        }
                    } else {
                        // Configure kubeconfig dynamically for EKS
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                            sh """
                                aws eks update-kubeconfig --region ${AWS_REGION} --name eks-X10-prod-01
                            """
                            // Run Helm deployment with KUBECONFIG set for EKS
                            sh 'helm upgrade --install my-polybot-app ./my-polybot-app-chart --namespace den-pollyapp'
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
                            sh 'kubectl apply -f argocd-config/application.yaml -n den-argo'
                        }
                    } else {
                        sh 'kubectl apply -f argocd-config/application.yaml -n den-argo'
                    }
                }
            }
        }

        stage('Sync ArgoCD Application') {
            steps {
                script {
                    if (params.AGENT_TYPE == 'kubernetes') {
                        container('jenkins-agent') {
                            sh 'kubectl -n den-argo patch application my-polybot-app --type merge -p \'{"metadata": {"annotations": {"argocd.argoproj.io/sync-wave": "-1"}}}\''
                        }
                    } else {
                        sh 'kubectl -n den-argo patch application my-polybot-app --type merge -p \'{"metadata": {"annotations": {"argocd.argoproj.io/sync-wave": "-1"}}}\''
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
