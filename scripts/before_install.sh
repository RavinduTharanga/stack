#!/bin/bash

# Set the environment variable for non-interactive installation
export DEBIAN_FRONTEND=noninteractive

# Update package lists
sudo apt-get update

# Install Apache and its dependencies
sudo apt-get install -y apache2

# Any other dependencies
# sudo apt-get install -y <other-packages>
