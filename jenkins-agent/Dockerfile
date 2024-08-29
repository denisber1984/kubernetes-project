# Use the official Jenkins inbound agent as the base image
FROM jenkins/inbound-agent:latest

# Switch to the root user to install packages
USER root

# Update package lists and install Docker CLI using apt-get
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common && \
    apt-get install -y docker.io

# Revert back to Jenkins user
USER jenkins

# Entry point
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/jenkins-agent"]
