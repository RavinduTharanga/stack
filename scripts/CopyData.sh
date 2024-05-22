#!/bin/bash

# Define the source directory of the data
DATA_SOURCE=/
# Define the destination directory
DESTINATION_DIR=/home/bitnami/stack

# Check if the source directory exists
if [ -d "$DATA_SOURCE" ]; then
  echo "Copying data..."
  cp -r "$DATA_SOURCE"/* "$DESTINATION_DIR"
  echo "Data copied successfully."
else
  echo "Data source directory not found: $DATA_SOURCE"
  exit 1
fi

