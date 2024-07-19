#!/usr/bin/env bash
###################################################################
# Get artifacts from a MLflow run
# Params
#   Host. Hostname of the MLflow server
#   Model name. Name of the model to download
#   Model version. Version of the model to download
#   Username. Username for the MLflow server
#   Password. Password for the MLflow server
###################################################################

# Stop on errors
set -e

# Check if the required arguments were passed
if [ $# -ne 5 ]; then
    echo "Usage: $0 <host> <model_name> <model_version> <username> <password>"
    exit 1
fi

# Constants
DESTINATION_DIR="artifacts"

# Variables
HOST=$1
MODEL=$2
VERSION=$3
USERNAME=$4
PASSWORD=$5

MLFLOW_SERVER_URL="http://${HOST}:5000"

# Create destination directory
mkdir -p "${DESTINATION_DIR}"

# Get artifacts
#echo mlflow artifacts download -r "$RUN_ID" -h "$HOST" .

# Get artifact url
echo curl -u "${USERNAME}:${PASSWORD}" -L "${MLFLOW_SERVER_URL}/api/2.0/mlflow/model-versions/get-download-uri?name=${MODEL}&version=${VERSION}"

# # Download the artifacts
# echo curl -u "${USERNAME}:${PASSWORD}" -L "${MLFLOW_SERVER_URL}/api/2.0/mlflow/artifacts/download?run_id=${RUN_ID}&path=${ARTIFACT_PATH}" --output "${DESTINATION_DIR}/artifacts.zip"
