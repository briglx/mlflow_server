#!/bin/bash

# Variables
PROJ_ROOT_PATH=/mlflow_server
ARTIFACT_ROOT="${PROJ_ROOT_PATH}/mlartifacts"
HOST="0.0.0.0"
PORT=${SERVER_PORT:-80}
LOGGING_CONF="${PROJ_ROOT_PATH}/mlflow_logging.conf"

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

echo "Starting MLflow server with the following parameters:"
echo "Host: $HOST, Port: $PORT, Logging configuration: $LOGGING_CONF"
mlflow server  \
  --host "$HOST" --port "$PORT" \
  --serve-artifacts  \
  --backend-store-uri sqlite:///mlflow.db \
  --gunicorn-opts "--log-level=debug --log-config $LOGGING_CONF" &

# Wait for the server to start
sleep 5
# Check if the server is running
curl -X GET "http://$HOST:$PORT/health"
echo "MLflow server is running at http://$HOST:$PORT"
# Keep the container running
tail -f /dev/null
