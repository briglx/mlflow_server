FROM mcr.microsoft.com/azureml/minimal-ubuntu22.04-py39-cpu-inference:latest

ARG ARTIFACT_PATH=/app

# Model
COPY ${ARTIFACT_PATH} /var/azureml-app/azureml-models
ENV AZUREML_MODEL_DIR=/var/azureml-app/azureml-models

# Install dependencies from conda.yaml
RUN conda env create -f conda.yaml

# Point to scoring script as main.py
