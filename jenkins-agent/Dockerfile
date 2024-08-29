# Use the official Jenkins inbound agent as the base image
FROM jenkins/inbound-agent:latest

# Switch to the root user to install packages
USER root

# Update package lists and install dependencies
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Install Docker using the official get.docker.com script
RUN curl -fsSL https://get.docker.com | sh

# Ensure Docker is in the correct path
RUN ln -s /usr/local/bin/docker /usr/bin/docker || true

# Revert back to Jenkins user
USER jenkins

# Entry point
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/jenkins-agent"]
