# Deploy a minimal custom container

```bash
image_name="online_endpoint/minimal:latest"
project_root="/workspaces/mlflow_server"
dockerfile_path="${project_root}/online_endpoint/minimal/Dockerfile"
server_version="1.3.2"
artifact_path="./artifacts/iris_model"

# Build image
docker build --build-arg "ARTIFACT_PATH=$artifact_path" --build-arg "SERVER_VERSION=$server_version" -t "$image_name" -f "${dockerfile_path}" "${project_root}"

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
