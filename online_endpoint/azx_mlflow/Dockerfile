FROM mcr.microsoft.com/azureml/mlflow-ubuntu18.04-py37-cpu-inference:latest

ARG ARTIFACT_PATH=/app
ARG BASE_PATH=./

USER dockeruser

# Configure Model and Server paths
ENV APP_PATH=/var/azureml-app
ENV APP_MODEL_PATH=${APP_PATH}/model
ENV APP_SERVER_PATH=${APP_PATH}/server
ENV USER_ENV=userenv

# Conda is already installed
ENV CONDA_ENV_DIR=/opt/miniconda/envs
ENV AZUREML_MODEL_DIR=$APP_MODEL_PATH
ENV AZUREML_CONDA_ENVIRONMENT_PATH="$CONDA_ENV_DIR/$USER_ENV"
ENV PATH="$AZUREML_CONDA_ENVIRONMENT_PATH/bin:$PATH"
ENV LD_LIBRARY_PATH="$AZUREML_CONDA_ENVIRONMENT_PATH/lib:$LD_LIBRARY_PATH"
ENV MLFLOW_MODEL_FOLDER=""

# Copy conda environment file and server requirements
RUN mkdir -p $APP_MODEL_PATH && \
    mkdir -p $APP_SERVER_PATH
COPY ${ARTIFACT_PATH} $APP_MODEL_PATH
COPY ${BASE_PATH}/requirements.txt $APP_SERVER_PATH/requirements.txt

# COPY ${ARG_ARTIFACT_PATH} /var/azureml-app/azureml-models
# RUN conda env create -n userenv -f "/var/azureml-app/azureml-models/conda.yaml"

# Create a single conda environment and install everything in one step
# RUN conda env create -n userenv -f /tmp/model/conda.yaml && \
#     source activate userenv && \
#     pip install -r /tmp/requirements.txt && \
#     conda clean --all --yes && \
#     rm -rf /root/.cache/pip /tmp/conda.yaml /tmp/requirements.txt

# Create conda environment from model conda.yaml and install server requirements
RUN conda env create -n $USER_ENV -f ${APP_MODEL_PATH}/conda.yaml && \
    export SERVER_VERSION=$(pip show azureml-inference-server-http | grep Version | sed -e 's/.*: //')  && \
    $AZUREML_CONDA_ENVIRONMENT_PATH/bin/pip install -r $APP_SERVER_PATH/requirements.txt

# Expose necessary ports
EXPOSE 5001

# Start the service
CMD ["runsvdir", "/var/runit"]
