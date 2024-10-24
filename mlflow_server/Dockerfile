FROM mcr.microsoft.com/devcontainers/python:3.12-bullseye

ARG SERVER_PORT=80
ENV SERVER_PORT=$SERVER_PORT

WORKDIR /mlflow_server

# Install Required Packages
COPY ./mlflow_server/requirements.txt /tmp/pip-tmp/
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
    && rm -rf /tmp/pip-tmp

# Configure MLflow Server
RUN mkdir -p mlartifacts
ENV ARTIFACT_ROOT="/mlartifacts"
ENV LOGGING_CONF="mlflow_logging.conf"

# Copy MLflow Server Files
COPY ./mlflow_server/start_mlflow.sh /mlflow_server
COPY ./mlflow_server/mlflow_logging.conf /mlflow_server

# # Configure MLflow Server as a Systemd Service
# COPY ./mlflow_server/mlflow.service /etc/systemd/system/mlflow.service

EXPOSE $SERVER_PORT
CMD ["./start_mlflow.sh"]
