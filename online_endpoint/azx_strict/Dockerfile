FROM mcr.microsoft.com/azureml/minimal-ubuntu22.04-py39-cpu-inference:latest

ARG ARG_ARTIFACT_PATH=/app
ARG ARG_BASE_PATH=./
ARG ARG_CONDA_DEFAULT_ENV=userenv

USER dockeruser

# Conda is already installed
ENV CONDA_ENV_DIR=/opt/miniconda/envs

# Install our Model dependencies
COPY ${ARG_ARTIFACT_PATH} /var/azureml-app/azureml-models
ENV AZUREML_MODEL_DIR=/var/azureml-app/azureml-models
RUN conda env create -n ${ARG_CONDA_DEFAULT_ENV} -f "/var/azureml-app/azureml-models/conda.yaml"

# Activate conda environment
ENV AZUREML_CONDA_ENVIRONMENT_PATH="/opt/miniconda/envs/${ARG_CONDA_DEFAULT_ENV}"
ENV CONDA_DEFAULT_ENV="${ARG_CONDA_DEFAULT_ENV}"
ENV PATH="/opt/miniconda/envs/${ARG_CONDA_DEFAULT_ENV}/bin:$PATH"
ENV LD_LIBRARY_PATH="$AZUREML_CONDA_ENVIRONMENT_PATH/lib"

# Install Required dependencies
COPY ${ARG_BASE_PATH}/requirements.txt /tmp
# Activate the environment
SHELL ["conda", "run", "-n", "userenv", "/bin/bash", "-c"]
RUN pip install -r /tmp/requirements.txt

# Copy files
COPY ${ARG_BASE_PATH} /tmp

# Run exec azmlinfsrv --entry_script /var/azureml-app/score.py --port 31311
ENTRYPOINT ["./entrypoint.sh"]
CMD ["azmlinfsrv", "--entry_script", "/var/azureml-app/score.py", "--port", "31311"]
