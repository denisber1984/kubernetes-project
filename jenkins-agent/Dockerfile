# Start with the Jenkins inbound-agent as the base image
FROM jenkins/inbound-agent:latest

# Switch to root user to install Docker and Helm
USER root

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common \
        lsb-release

# Add Docker’s official GPG key
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

# Set up the stable repository for Docker
RUN echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list

# Install Docker Engine
RUN apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io

# Ensure Docker is linked correctly in /usr/bin if not already present
RUN if [ ! -f /usr/bin/docker ]; then ln -s /usr/local/bin/docker /usr/bin/docker; fi

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Switch back to the Jenkins user
USER jenkins
