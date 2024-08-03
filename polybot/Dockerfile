# Use an official Python runtime as a parent image
FROM python:3.8

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the requirements file to the working directory
COPY requirements.txt ./

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Install pip3, pytest, and unittest2 for running unit tests
RUN apt-get update && apt-get install -y python3-pip && pip3 install pytest unittest2

# Copy the rest of the application source code to the working directory
COPY . .

# Make port 8443 available to the world outside this container
EXPOSE 8443

# Define environment variable for Flask
ENV FLASK_APP=app.py

# Run the app when the container launches
CMD ["flask", "run", "--host=0.0.0.0", "--port=8443"]
