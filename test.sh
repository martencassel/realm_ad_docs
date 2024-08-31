#!/bin/bash

set -x

CONTAINER_NAME="install-test-container"

# Function to log info messages with color
log_info() {
  GREEN='\033[0;32m'
  NC='\033[0m' # No Color
  echo -e "${GREEN}INFO: $1${NC}"
}
# Remove the container if it already exists
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  log_info "Removing existing container $CONTAINER_NAME..."
  docker rm -f $CONTAINER_NAME
fi

# Build the Docker image
log_info "Building the Docker image..."
docker build -t install-test --no-cache .

# Run the Docker container in detached mode
log_info "Running the Docker container in detached mode..."
docker run -d --name $CONTAINER_NAME install-test bats /usr/local/bin/test_install_from_source.bats

# Get the container ID of the last running container
LAST_CONTAINER_ID=$(docker ps -l -q)

# Tail the log file inside the running container
log_info "Tailing the log file inside the running container..."
docker exec -it $LAST_CONTAINER_ID tail -f /tmp/install_from_source.log
