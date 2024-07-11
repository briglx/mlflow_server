#!/bin/bash

# Variables
PROJ_ROOT_PATH=$(git rev-parse --show-toplevel)
ARTIFACT_ROOT="${PROJ_ROOT_PATH}/mlartifacts"
HOST="0.0.0.0"
PORT=5000
LOGGING_CONF="mlflow_logging.conf"

# Check if ARTIFACT_ROOT exists, if not, create it with proper permissions
if [ ! -d "$ARTIFACT_ROOT" ]; then
  echo "The ARTIFACT_ROOT path does not exist. $ARTIFACT_ROOT"
else
  echo "The ARTIFACT_ROOT path exists. $ARTIFACT_ROOT"
fi

# pyenv, pyenv-virtualenv
if [ -s .python-version ]; then
    PYENV_VERSION=$(head -n 1 .python-version)
    export PYENV_VERSION
fi

if [ -f "${PROJ_ROOT_PATH}/venv/bin/activate" ]; then
  activate_path="${PROJ_ROOT_PATH}/venv/bin/activate"
  echo "Found environment in venv $activate_path"
  # shellcheck disable=SC1090,SC1091
  . "$activate_path"
fi

if [ -f "${PROJ_ROOT_PATH}/.venv/bin/activate" ]; then
  activate_path="${PROJ_ROOT_PATH}/.venv/bin/activate"
  echo "Found environment in .venv $activate_path"
  # shellcheck disable=SC1090,SC1091
  . "$activate_path"
fi

# Simple startup ========================================
# mlflow server \
#     --host "$HOST" --port "$PORT"


# Anotherway to start it ================================
# Define paths and environment variables
export MLFLOW_TRACKING_URI="http://$HOST:$PORT"
export BACKEND_STORE_URI="sqlite:///mlflow.db"
export ARTIFACT_ROOT="file:$ARTIFACT_ROOT"

cd "$PROJ_ROOT_PATH" || exit

gunicorn --log-config "$LOGGING_CONF" -b "$HOST:$PORT" -w 4 mlflow.server:app



# # Start MLflow server with logging configuration ========
# mlflow server \
#     --artifacts-destination s3://bucket \
#     --backend-store-uri postgresql://user:password@localhost:5432/mlflowdb \
#     --host "$HOST" --port "$PORT" \
#     --gunicorn-opts "--log-config $LOGGING_CONF"
