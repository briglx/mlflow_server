#!/usr/bin/env bash
###################################################################
# Serve a model using MLflow
# Params
#   Host. Hostname of the MLflow server
#   Model name. Name of the model to serve
#   Model version. Version of the model to serve
#   Username. Username for the MLflow server
#   Password. Password for the MLflow server
###################################################################

# Stop on errors
set -e

echo "Serving model with release version: $RELEASE_VERSION"

# Serve the model
mlflow models serve --no-conda -m "file:///app" -h "0.0.0.0" -p "5000"
