FROM mcr.microsoft.com/azureml/minimal-ubuntu22.04-py39-cpu-inference:latest

ARG ARTIFACT_PATH=/app

USER dockeruser

# Conda is already installed
ENV CONDA_ENV_DIR=/opt/miniconda/envs
ENV SERVER_VERSION=1.3.2

# We will pre-install the conda environment at build time
# or can be added alongside the image in the environment yaml definition for Azure to build

# Create a new conda environment and install the same version of the server
COPY ${ARTIFACT_PATH} /var/azureml-app/azureml-models
RUN conda env create -n userenv -f /var/azureml-app/azureml-models/conda.yaml
RUN $CONDA_ENV_DIR/userenv/bin/pip install azureml-inference-server-http==$SERVER_VERSION

# Update environment variables
ENV AZUREML_CONDA_ENVIRONMENT_PATH="$CONDA_ENV_DIR/userenv"
ENV PATH="$AZUREML_CONDA_ENVIRONMENT_PATH/bin:$PATH"
# ENV LD_LIBRARY_PATH="$AZUREML_CONDA_ENVIRONMENT_PATH/lib:$LD_LIBRARY_PATH"
