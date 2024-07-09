#!/bin/bash

# Variables
ARTIFACT_ROOT="./artifact/root"
HOST="0.0.0.0"
PORT=5000
LOGGING_CONF="mlflow_logging.conf"

# Create artifact root directory if it does not exist
mkdir -p $ARTIFACT_ROOT

# Start MLflow server with logging configuration
mlflow server \
    --default-artifact-root $ARTIFACT_ROOT \
    --host $HOST --port $PORT \
    --gunicorn-opts "--log-config $LOGGING_CONF"
