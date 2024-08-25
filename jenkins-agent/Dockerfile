# Start with jenkins/agent as the base image
FROM jenkins/agent

# Copy the Docker client from the Docker image
COPY --from=docker /usr/local/bin/docker /usr/local/bin/

# Install Python
USER root
RUN apt-get update && apt-get install -y python3 python3-pip

# Switch back to the Jenkins user
USER jenkins
