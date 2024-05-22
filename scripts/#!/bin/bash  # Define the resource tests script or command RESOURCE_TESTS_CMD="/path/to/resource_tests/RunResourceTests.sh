#!/bin/bash

# Define the resource tests script or command
RESOURCE_TESTS_CMD=/

# Check if the resource tests command exists
if [ -x "$RESOURCE_TESTS_CMD" ]; then
  echo "Running resource tests..."
  "$RESOURCE_TESTS_CMD"
  echo "Resource tests completed."
else
  echo "Resource tests command not found or not executable: $RESOURCE_TESTS_CMD"
  exit 1
fi
