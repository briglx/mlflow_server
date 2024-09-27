# Online Endpoint with Docker Container

There are various way to serve up models using a docker image.

| Method                                                                                                                          | Servables                                                                                                                  | Protocols                                | Docker File                                                | Example                                                                                         |
| ------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [TensorFlow Serving](https://github.com/tensorflow/serving)                                                                     | Tensorflow models, embeddings, vocabularies, feature transformations and even non-Tensorflow-based machine learning models | gRPC as well as HTTP inference endpoints | [Dockerfile](https://hub.docker.com/r/tensorflow/serving/) | [Example](https://github.com/tensorflow/serving/blob/master/tensorflow_serving/g3doc/docker.md) |
| [mlflow models serve](https://mlflow.org/docs/latest/models.html)                                                               | MLflow Artifacts                                                                                                           | REST API & TBD                           | tbd                                                        | tbd                                                                                             |
| [ONNX Runtime](https://example.com)                                                                                             | tbd                                                                                                                        | tbd                                      | tbd                                                        | tbd                                                                                             |
| [Ollama](https://ollama.com/)                                                                                                   | tbd                                                                                                                        | tbd                                      | tbd                                                        | tbd                                                                                             |
| [vLLM](https://github.com/vllm-project/vllm)                                                                                    | tbd                                                                                                                        | tbd                                      | tbd                                                        | tbd                                                                                             |
| [Azure ML](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-custom-container?view=azureml-api-2&tabs=cli) | tbd                                                                                                                        | tbd                                      | tbd                                                        | tbd                                                                                             |

# Build Docker Image

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
$ conda activate mlflow-env
$ mlflow models serve -m "file:///app" -h "0.0.0.0" -p 5000 --no-conda

# Check liveness
curl --header "Content-Type: application/json" --request GET http://localhost:5000/version
# Check prediction
curl --header "Content-Type: application/json" --request POST --data @"${artifact_path}/input_example.json" http://localhost:5000/invocations
```

# Deploy Model to AML Online Endpoint

```python


```

# References

- Example Notebook https://github.com/Azure/azureml-examples/blob/main/sdk/python/endpoints/online/custom-container/online-endpoints-custom-container.ipynb
- https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-custom-container?view=azureml-api-2&tabs=cli
