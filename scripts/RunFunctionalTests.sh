#!/bin/bash

# Define the functional tests script or command
FUNCTIONAL_TESTS_CMD=/

# Check if the functional tests command exists
if [ -x "$FUNCTIONAL_TESTS_CMD" ]; then
  echo "Running functional tests..."
  "$FUNCTIONAL_TESTS_CMD"
  echo "Functional tests completed."
else
  echo "Functional tests command not found or not executable: $FUNCTIONAL_TESTS_CMD"
  exit 1
fi
