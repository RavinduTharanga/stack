#!/bin/bash

# Define the service to monitor
SERVICE_NAME=my_service

# Check if the service is running
if pgrep -x "$SERVICE_NAME" > /dev/null
then
  echo "$SERVICE_NAME is running."
else
  echo "$SERVICE_NAME is not running."
  # Optionally, restart the service
  # systemctl restart $SERVICE_NAME
  exit 1
fi
