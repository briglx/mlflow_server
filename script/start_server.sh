#!/bin/bash

# Variables
PROJ_ROOT_PATH=$(cd "$(dirname "$0")"/..; pwd)
ARTIFACT_ROOT="${PROJ_ROOT_PATH}/artifact/root"
HOST="0.0.0.0"
PORT=5000
LOGGING_CONF="mlflow_logging.conf"

# Check if ARTIFACT_ROOT path exists
if [ -d "$ARTIFACT_ROOT" ]; then
    echo "The ARTIFACT_ROOT path exists. $ARTIFACT_ROOT"
else
    echo "The ARTIFACT_ROOT path does not exist. $ARTIFACT_ROOT"
fi

# Start MLflow server with logging configuration
mlflow server \
    --default-artifact-root "$ARTIFACT_ROOT" \
    --host "$HOST" --port "$PORT" \
    --gunicorn-opts "--log-config $LOGGING_CONF"
