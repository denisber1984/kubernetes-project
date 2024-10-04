pipeline {
    parameters {
        choice(name: 'AGENT_TYPE', choices: ['kubernetes', 'ec2'], description: 'Choose the type of agent to run the job')
    }

    // Use 'none' for the global agent to dynamically assign agents later in the pipeline
    agent none

    environment {
        KUBECONFIG = "${env.WORKSPACE}/.kube/config"
    }

    stages {
        stage('Select Agent') {
            agent none // No global agent, agents will be selected dynamically
            steps {
                script {
                    if (params.AGENT_TYPE == 'kubernetes') {
                        podTemplate(containers: [
                          containerTemplate(
                            name: 'jenkins-agent',
                            image: 'denisber1984/jenkins-agent:helm-kubectl',
                            ttyEnabled: true,
                            command: 'cat',
                            privileged: true
                          )],
                          volumes: [hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')]
                        ) {
                            node(POD_LABEL) {
                                runPipeline()
                            }
                        }
                    } else if (params.AGENT_TYPE == 'ec2') {
                        node('ec2-agent') {
                            runPipeline()
                        }
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

def runPipeline() {
    stage('Checkout SCM') {
        checkout scm
        sh 'ls -la'
    }

    stage('Install Python Requirements') {
        sh """
            python3 -m venv venv
            . venv/bin/activate
            pip install pytest unittest2 pylint flask telebot Pillow loguru matplotlib
        """
    }

    stage('Unittest') {
        sh """
            python3 -m venv venv
            . venv/bin/activate
            python -m pytest --junitxml results.xml polybot/test
        """
    }

    stage('Build Docker Image') {
        script {
            def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()

            if (params.AGENT_TYPE == 'kubernetes') {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh "docker build -t denisber1984/mypolybot:${commitHash} polybot/"
                    sh "echo ${PASS} | docker login -u ${USER} --password-stdin"
                    sh "docker push denisber1984/mypolybot:${commitHash}"
                }
            } else if (params.AGENT_TYPE == 'ec2') {
                def ecrRepo = "023196572641.dkr.ecr.us-east-2.amazonaws.com/denber1984/app-repo"
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    sh "aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${ecrRepo}"
                    sh "docker build -t ${ecrRepo}:${commitHash} polybot/"
                    sh "docker push ${ecrRepo}:${commitHash}"
                }
            }
        }
    }

    stage('Helm Deployment') {
        withEnv(["KUBECONFIG=${env.WORKSPACE}"]) {
            sh 'helm upgrade --install my-polybot-app ./my-polybot-app-chart --namespace demoapp'
        }
    }

    stage('Create/Update ArgoCD Application') {
        sh 'kubectl apply -f argocd-config/application.yaml -n argocd'
    }

    stage('Sync ArgoCD Application') {
        sh 'kubectl -n argocd patch application my-polybot-app --type merge -p \'{"metadata": {"annotations": {"argocd.argoproj.io/sync-wave": "-1"}}}\''
    }
}
