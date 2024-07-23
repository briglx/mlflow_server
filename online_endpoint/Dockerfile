# Base image
FROM continuumio/miniconda3:latest

# Set the working directory
WORKDIR /app

ARG ARTIFACT_PATH=/app
ARG RELEASE_VERSION=0.0.1

RUN echo 'alias ll='"'"'ls $LS_OPTIONS -al'"'"'' >> /etc/bash.bashrc

# Copy the MLFlow artifacts to the container
COPY ${ARTIFACT_PATH} /app

# Install dependencies
RUN conda env create -f conda.yaml

# Activate the environment
SHELL ["conda", "run", "-n", "mlflow-env", "/bin/bash", "-c"]
RUN echo "Make sure the environment is activated"
RUN conda env list
RUN python -c "import mlflow"

# Expose the default MLFlow port
EXPOSE 5000

# Copy Serving Script to the container
COPY ./script/mlflow_serve.sh /app/entrypoint.sh

#  Serve the model
CMD ["conda", "run", "--no-capture-output", "-n", "mlflow-env", "./entrypoint.sh"]
