# Deploy a minimal custom container

From [azureml-examples minimal](https://github.com/Azure/azureml-examples/blob/main/cli/endpoints/online/custom-container/minimal/single-model/pip-in-dockerfile/minimal-single-model-pip-in-dockerfile-deployment.yml)

```bash
image_name="online_endpoint/minimal:latest"
project_root="/workspaces/mlflow_server"
dockerfile_path="${project_root}/online_endpoint/minimal/Dockerfile"
artifact_path="./artifacts/iris_model"

# Build image
docker build -t "$image_name" -f "${dockerfile_path}" "${project_root}"

# Run container
docker run -p 5000:5000 "$image_name"

# Interactive shell
docker run -it --entrypoint /bin/bash -p 5000:5000  "$image_name"
```
