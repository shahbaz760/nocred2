#!/bin/bash

# Define the SNS topic ARN
SNS_TOPIC_ARN="arn:aws:sns:us-east-2:637527414831:nocred2"

# Function to send SNS email notification
send_sns_notification() {
    local subject=$1
    local message=$2
    aws sns publish --topic-arn "$SNS_TOPIC_ARN" --message "$message" --subject "$subject"
}

# Trap errors and handle failures
trap 'send_sns_notification "Deployment Failed" "There was an error during the deployment process. Please check the logs." && exit 1' ERR

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

# Login to ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 637527414831.dkr.ecr.us-east-2.amazonaws.com

# Pull the latest docker image
sudo docker pull 637527414831.dkr.ecr.us-east-2.amazonaws.com/nocred2:latest

# Check if a Docker container is running on port 80
CONTAINER_ID=$(sudo docker ps --filter "publish=80" --format "{{.ID}}")

if [ -z "$CONTAINER_ID" ]; then
    echo "No Docker container is running on port 80. Moving forward..."
else
    # Get the container name for better identification
    CONTAINER_NAME=$(sudo docker ps --filter "publish=80" --format "{{.Names}}")

    echo "Docker container $CONTAINER_NAME (ID: $CONTAINER_ID) is running on port 80."

    # Stop the Docker container
    echo "Stopping Docker container $CONTAINER_NAME..."
    sudo docker stop $CONTAINER_ID

    # Optionally, remove the container
    echo "Removing Docker container $CONTAINER_NAME..."
    sudo docker rm $CONTAINER_ID

    echo "Docker container $CONTAINER_NAME has been stopped and removed."
fi

# Create a unique container name
UNIQUE_ID=$(date +%s)
CONTAINER_NAME="frontend-${UNIQUE_ID}"

# Start a new container
echo "Starting a new container with name $CONTAINER_NAME..."
sudo docker run -d --name $CONTAINER_NAME --restart always -p 80:80 637527414831.dkr.ecr.us-east-2.amazonaws.com/nocred2:latest

# Clean up unused Docker resources
echo "Cleaning up unused Docker resources..."
sudo docker system prune -a --force

# Send success notification
send_sns_notification "Deployment Success" "Code deployed successfully. The new container $CONTAINER_NAME is now running."
