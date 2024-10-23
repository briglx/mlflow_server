FROM mcr.microsoft.com/azureml/minimal-ubuntu22.04-py39-cpu-inference:latest

ARG ARG_ARTIFACT_PATH=/app
ARG ARG_BASE_PATH=./

USER dockeruser

# Conda is already installed
ENV CONDA_ENV_DIR=/opt/miniconda/envs

# Install Required dependency
RUN /opt/miniconda/bin/python -m pip install azureml-inference-server-http azureml-ai-monitoring azureml-defaults

# Install our Code
COPY ${ARG_BASE_PATH}/score.py /var/azureml-app
ENV AZUREML_ENTRY_SCRIPT=score.py

# Install our Model
COPY ${ARG_ARTIFACT_PATH} /var/azureml-app/azureml-models
ENV AZUREML_MODEL_DIR=/var/azureml-app/azureml-models

# ENV ENTRY_SCRIPT_DIR=/var/azureml-app
ENV AZUREML_EXTRA_CONDA_YAML_ABS_PATH=/var/azureml-app/azureml-models/conda.yaml
