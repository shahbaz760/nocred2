#!/bin/bash

# Check if Docker is already installed
if ! command -v docker >/dev/null 2>&1; then
    # Add Docker's official GPG key
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the Docker repository to Apt sources
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update apt and install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "Docker is already installed."
fi



#Login to ecr 
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 637527414831.dkr.ecr.us-east-2.amazonaws.com


#Pull latest docker iamge
docker pull 637527414831.dkr.ecr.us-east-2.amazonaws.com/nocred:latest

#check if there is any instance already running 
# Check which Docker container is running on port 80
CONTAINER_ID=$(docker ps --filter "publish=80" --format "{{.ID}}")

if [ -z "$CONTAINER_ID" ]; then
    echo "No Docker container is running on port 80."
    exit 1
fi

# Get the container name for better identification
CONTAINER_NAME=$(docker ps --filter "publish=80" --format "{{.Names}}")

echo "Docker container $CONTAINER_NAME (ID: $CONTAINER_ID) is running on port 80."

# Stop the Docker container
echo "Stopping Docker container $CONTAINER_NAME..."
docker stop $CONTAINER_ID

# Optionally, remove the container
echo "Removing Docker container $CONTAINER_NAME..."
docker rm $CONTAINER_ID

echo "Docker container $CONTAINER_NAME has been stopped and removed."


#Start a new container 
sudo docker run -d --name $CONTAINER_NAME --restart always -p 80:80 637527414831.dkr.ecr.us-east-2.amazonaws.com/nocred:latest