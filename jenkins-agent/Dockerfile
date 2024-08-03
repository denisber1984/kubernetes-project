# Start with amazonlinux:2 as installer
FROM amazonlinux:2 as installer

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN yum update -y \
    && yum install -y unzip \
    && unzip awscliv2.zip \
    && ./aws/install --bin-dir /aws-cli-bin/

# Install Snyk
RUN mkdir /snyk && cd /snyk \
    && curl https://static.snyk.io/cli/v1.666.0/snyk-linux -o snyk \
    && chmod +x ./snyk

# Start with jenkins/agent as the main image
FROM jenkins/agent

# Copy the Docker client from the Docker image
COPY --from=docker /usr/local/bin/docker /usr/local/bin/

# Copy the AWS CLI and Snyk from the installer image
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/
COPY --from=installer /snyk/snyk /usr/local/bin/

# Install Python
USER root
RUN apt-get update && apt-get install -y python3 python3-pip

# Switch back to the Jenkins user
USER jenkins
