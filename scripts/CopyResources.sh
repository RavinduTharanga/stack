#!/bin/bash

# Define the source directory of the resources
RESOURCE_SOURCE=/

# Define the destination directory
DESTINATION_DIR=/home/bitnami/stack

# Check if the source directory exists
if [ -d "$RESOURCE_SOURCE" ]; then
  echo "Copying resources..."
  cp -r "$RESOURCE_SOURCE"/* "$DESTINATION_DIR"
  echo "Resources copied successfully."
else
  echo "Resource source directory not found: $RESOURCE_SOURCE"
  exit 1
fi
