# Dockerfile for Jenkins Agent
# Start with the Jenkins inbound agent as the base image
FROM jenkins/inbound-agent:latest

# Switch to root user to install packages
USER root

# Install Docker CLI and other dependencies
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/kubectl

# Ensure helm and kubectl are in PATH
RUN ln -s /usr/local/bin/helm /usr/bin/helm && \
    ln -s /usr/local/bin/kubectl /usr/bin/kubectl

# Switch back to the Jenkins user
USER jenkins
