#!/bin/bash

# Variables
# PROJ_ROOT_PATH=$(git rev-parse --show-toplevel)
# ARTIFACT_ROOT="${PROJ_ROOT_PATH}/artifacts"


# Install PostgreSQL ==========

# # Update package lists
# echo "Updating package lists..."
# sudo apt-get update

# # Install PostgreSQL
# echo "Installing PostgreSQL..."
# sudo apt-get install -y postgresql postgresql-contrib

# # Start the PostgreSQL service
# echo "Starting PostgreSQL service..."
# sudo systemctl start postgresql

# # Enable PostgreSQL service to start on boot
# echo "Enabling PostgreSQL to start on boot..."
# sudo systemctl enable postgresql

# echo "PostgreSQL installation completed successfully."

# Add user to docker group ==========
sudo usermod -aG docker "$USER"

#=====================

export MLFLOW_S3_ENDPOINT_URL=http://localhost:9000 # Replace this with remote storage endpoint e.g. s3://my-bucket in real use cases
export AWS_ACCESS_KEY_ID=minio_user
export AWS_SECRET_ACCESS_KEY=minio_password


#====================


# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Install requirements
pip install -r requirements.txt

# # Check if ARTIFACT_ROOT exists, if not, create it with proper permissions
# if [ ! -d "$ARTIFACT_ROOT" ]; then
#   echo "The ARTIFACT_ROOT path does not exist. $ARTIFACT_ROOT"
#   mkdir -p "$ARTIFACT_ROOT"
#   chmod 755 "$ARTIFACT_ROOT" # Adjust permissions as necessary
# else
#   echo "The ARTIFACT_ROOT path exists. $ARTIFACT_ROOT"
# fi
