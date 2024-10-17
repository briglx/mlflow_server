# Online Endpoint with Docker Container

There are various way to serve up models using a docker image.

| Method                                                                                                                                                                                                     | Servables                                                                                                                                                    | Protocols                                | Docker File                                                                                                                                                                                         | Example                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| [TensorFlow Serving](https://github.com/tensorflow/serving)                                                                                                                                                | Tensorflow models, embeddings, vocabularies, feature transformations and even non-Tensorflow-based machine learning models                                   | gRPC as well as HTTP inference endpoints | [Dockerfile](https://hub.docker.com/r/tensorflow/serving/)                                                                                                                                          | [Example](https://github.com/tensorflow/serving/blob/master/tensorflow_serving/g3doc/docker.md)                                      |
| [mlflow models serve](https://mlflow.org/docs/latest/models.html)                                                                                                                                          | MLflow Artifacts                                                                                                                                             | REST API & TBD                           | tbd                                                                                                                                                                                                 | tbd                                                                                                                                  |
| [ONNX Runtime](https://example.com)                                                                                                                                                                        | tbd                                                                                                                                                          | tbd                                      | tbd                                                                                                                                                                                                 | tbd                                                                                                                                  |
| [Ollama](https://ollama.com/)                                                                                                                                                                              | tbd                                                                                                                                                          | tbd                                      | tbd                                                                                                                                                                                                 | tbd                                                                                                                                  |
| [vLLM](https://github.com/vllm-project/vllm)                                                                                                                                                               | tbd                                                                                                                                                          | tbd                                      | tbd                                                                                                                                                                                                 | tbd                                                                                                                                  |
| [Azure ML Inference Server HTTP](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-inference-server-http?view=azureml-api-2) [GitHub](https://github.com/microsoft/azureml-inference-server) | [Pytorch, Tensorflow models, Keras, AutoML](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-advanced-entry-script?view=azureml-api-1) | gRPC as well as HTTP inference endpoints | [Prebuilt Images](https://learn.microsoft.com/en-us/azure/machine-learning/concept-prebuilt-docker-images-inference?view=azureml-api-2) [Base Images](https://github.com/Azure/AzureML-Containers/) | [Example](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-extend-prebuilt-docker-image-inference?view=azureml-api-1) |
| r                                                                                                                                                                                                          | tbd                                                                                                                                                          | tbd                                      | tbd                                                                                                                                                                                                 | tbd                                                                                                                                  |
| torchserve                                                                                                                                                                                                 | tbd                                                                                                                                                          | tbd                                      | tbd                                                                                                                                                                                                 | tbd                                                                                                                                  |
| triton                                                                                                                                                                                                     | tbd                                                                                                                                                          | tbd                                      | tbd                                                                                                                                                                                                 | tbd                                                                                                                                  |

In addition, a model may depend on hardware like GPUs, TPUs, or other accelerators. This would require docker images to include software like CUDA, cuDNN, or other libraries.

# MLFlow Model Server

The MLFlow Model Server is a REST API that serves up MLFlow models. The server can be run locally or in a docker container. The server can be run in a docker container using the `mlflow models serve` command.

## Local file

```bash
artifact_path="${cwd}/artifacts/iris_model"
mlflow models serve --no-conda -m "file://${cwd}/artifacts/iris_model" -h "0.0.0.0" -p "5000"
```

## Build Docker Image

```bash
model_name="dev.mlflow-sample-model-test_script"
model_version=4
image="${model_name}_v${model_version}"

proj_version="${PROJ_VERSION}"
build_number=$(date +%Y%m%dT%H%M)
version="${proj_version}.dev${build_number}"

image_name="${image}:${version}"

# ./script/devops.sh build_image --name "$image_name" --version "$version"

project_root="/home/brlamore/src/mlflow_server"
dockerfile_path="${project_root}/online_endpoint/Dockerfile"
artifact_path="./artifacts/iris_model"

# Build image
docker build --build-arg "ARTIFACT_PATH=$artifact_path" --build-arg "RELEASE_VERSION=$version" -t "$image_name" -f "${dockerfile_path}" "${project_root}"

# Run container
docker run -p 5000:5000 "$image_name"

# Interactive shell
docker run -it --entrypoint /bin/bash -p 5000:5000  "$image_name"

# Start server
$ conda activate mlflow-env
$ mlflow models serve -m "file:///app" -h "0.0.0.0" -p 5000 --no-conda

# Check liveness
curl --header "Content-Type: application/json" --request GET http://localhost:5000/version
# Check prediction
curl --header "Content-Type: application/json" --request POST --data @"${artifact_path}/input_example.json" http://localhost:5000/invocations
```

# AML Inference Server HTTP

The [AzureML Inference Server](https://github.com/microsoft/azureml-inference-server/blob/main/docs/AzureMLInferenceServer.md) is used with most images in the Azure ML ecosystem, and is considered the primary component of the base image, as it contains the python assets required for inferencing.

## Local file

TBD

## Custom Code deployment

```bash
image_name="dev.ais_hello_world:latest"
project_root="/workspaces/mlflow_server"
dockerfile_path="${project_root}/online_endpoint/ais.Dockerfile"

# Build image
docker build -t "$image_name" -f "${dockerfile_path}" "${project_root}"

# Run container
docker run -p 5000:5000 "$image_name"

# Interactive shell
docker run -it --entrypoint /bin/bash -p 5000:5000  "$image_name"

# Start server
azmlinfsrv --entry_script score.py --port 5000

# Check liveness
curl -p 127.0.0.1:5000
curl --header "Content-Type: application/json" --request GET http://localhost:5000/

# Check prediction
curl -p 127.0.0.1:5000/score
curl --header "Content-Type: application/json" --request GET http://localhost:5000/score
```

### No Code deployment

```bash
image_name="dev.ais_hello_world:latest"
project_root="/workspaces/mlflow_server"
dockerfile_path="${project_root}/online_endpoint/ais.nocode.Dockerfile"
artifact_path="./artifacts/iris_model"

# Build image
docker build --build-arg "ARTIFACT_PATH=$artifact_path" -t "$image_name" -f "${dockerfile_path}" "${project_root}"

# Run container
docker run "$image_name"
docker run -it --entrypoint /bin/bash  "$image_name"
# Fails to load ... no script
```

# Deploy Model to AML Online Endpoint

```python


```

# References

- Example Notebook https://github.com/Azure/azureml-examples/blob/main/sdk/python/endpoints/online/custom-container/online-endpoints-custom-container.ipynb
- https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-custom-container?view=azureml-api-2&tabs=cli
- Extend AML Prebuilt docker images https://learn.microsoft.com/en-us/azure/machine-learning/how-to-extend-prebuilt-docker-image-inference?view=azureml-api-1
- Azure Custom Container Examples https://github.com/Azure/azureml-examples/blob/main/cli/endpoints/online/custom-container/README.md
