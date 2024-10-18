# Deploy a mlflow container

```bash
# image name and version
model_name=dev.ml_team.iris_classifier
model_version=1
base_image="mlflow"
image="${base_image}_${model_name}_v${model_version}"
version="2024.10.1.dev20241018T2105"
image_name="${image}:${version}"
# image_name="mlflow.dev.ml_team.iris_classifier_v1:2024.10.1.dev20241018T2105
# image_name="online_endpoint/mlflow:latest"
project_root="/workspaces/mlflow_server"
dockerfile_path="${project_root}/online_endpoint/mlflow/Dockerfile"
server_version="1.3.2"
artifact_path="./artifacts/iris_model"

# Build image
docker build \
        --build-arg "ARTIFACT_PATH=$artifact_path" \
        --build-arg "RELEASE_VERSION=$version" \
        --build-arg "SERVER_VERSION=$server_version" \
        -t "${image_name}" \
        -f "${dockerfile_path}" \
        "${project_root}"

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
