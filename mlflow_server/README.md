# MLFlow Artifact Tracking Server

MLFlow tracking server and artifact store. Azure Machine Learning (AML) and Databricks both implement an MLFlow tracking server. Below includes the steps to provision and deploy an MLFlow tracking server as a docker or vm. Also detail around Databricks model promotion.

![Architecture Overview](./docs/architecture_overview.svg)

## Provision Server

You can either provision with a Docker container (Recommended) or VM.

### Docker Provisioning

```bash
# Build Docker image
project_root=$(git rev-parse --show-toplevel)
dockerfile_path="${project_root}/mlflow_server/Dockerfile"
image_name="mlflow-server"

# Build image for local testing
docker build --build-arg "SERVER_PORT=5001" -t "${image_name}.dev" -f "${dockerfile_path}" "${project_root}"

# Run container locally
docker run -p 5001:5001 "${image_name}.dev"

# Interactive shell
docker run -it --entrypoint /bin/bash -p 5001:5001  "${image_name}.dev"
# Run the service
./start_mlflow.sh

# Check livliness
curl -p 127.0.0.1:5001/health
# Login to the tracking server http://localhost:5001

# Build for deployment
docker build -t "$image_name" -f "${dockerfile_path}" "${project_root}"
```

Deploy image to a new container app

```bash
# load .env vars (optional)
[ ! -f .env ] || eval "export $(grep -v '^#' .env | xargs)"
# or this version allows variable substitution and quoted long values
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

# Login to cloud cli. Only required once per install.
az login --tenant $AZURE_TENANT_ID
az acr login --name "${AZURE_CONTAINER_REGISTRY_NAME}"
docker login -u "$AZURE_CONTAINER_REGISTRY_USERNAME" -p "$AZURE_CONTAINER_REGISTRY_PASSWORD" "${AZURE_CONTAINER_REGISTRY_NAME}.azurecr.io"

registry_host="${AZURE_CONTAINER_REGISTRY_NAME}.azurecr.io"
namespace="infra"
current_date_time=$(date +"%Y%m%dT%H%M")
tag="2024.10.1.dev${current_date_time}"

# Tag and Publish Dev Version
docker tag "${image_name}" "${registry_host}/${namespace}/${image_name}:${tag}"
docker push "${registry_host}/${namespace}/${image_name}:${tag}"

# Tag and Publish Prod Version
docker tag "${image_name}" "${registry_host}/${namespace}/${image_name}:latest"
docker push "${registry_host}/${namespace}/${image_name}:latest"

# Create container app
# docker tag "${image_name}" "${AZURE_CONTAINER_REGISTRY_NAME}.azurecr.io/${image_name}"
# docker push "${AZURE_CONTAINER_REGISTRY_NAME}.azurecr.io/${image_name}"
response=$(az container create -g "$MLFOW_ACI_RESOURCE_GROUP" --name "mlflowserver" --image "${registry_host}/${namespace}/${image_name}:latest" --cpu 1 --memory 1 --registry-username "$AZURE_CONTAINER_REGISTRY_USERNAME"  --registry-password "$AZURE_CONTAINER_REGISTRY_PASSWORD" --ip-address Public --ports 80 443)
ip_address=$(echo "$response" | jq -r '.ipAddress.ip')
iso_date_utc=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
{
    echo ""
    echo "# Script ./mlflow_server/README.md - output variables."
    echo "# Generated on $iso_date_utc"
    echo "MLFLOW_TRACKING_IP=${ip_address}"
    echo "MLFLOW_TRACKING_URI=http://${ip_address}"
}>> "./.env"


# Check livliness
curl -p ${ip_address}/health
# Login to the tracking server http://${ip_address}:5001


```

### VM Provisioning

Create a new VM in Azure and run the following commands to provision the server.

```bash
# Install mlflow

# Need to ensure the following
PROJ_ROOT_PATH=/home/azureuser/mlfow_server
ARTIFACT_ROOT="${PROJ_ROOT_PATH}/mlartifacts"
HOST="0.0.0.0"
PORT=5000
LOGGING_CONF="mlflow_logging.conf"

mkdir $ARTIFACT_ROOT

# Setup virtual environment and install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Start MLFlow server
./script/start.sh

# Configure systemd file `/etc/systemd/system/mlflow.service` to start the MLFlow server on boot.
sudo cp ./mlflow.service /etc/systemd/system/mlflow.service

# Start the service
sudo systemctl daemon-reload
sudo systemctl start mlflow
sudo systemctl enable mlflow

# Check the status
sudo systemctl start mlflow
sudo systemctl stop mlflow
sudo systemctl restart mlflow
sudo systemctl status mlflow
journalctl -u mlflow
```

Login to the tracking server `http://<TRACKING_SERVER_IP>:5000`

```bash
# SSH into the Tracking Server
ssh -i ~/.ssh/id_rsa azureuser@$TRACKING_SERVER_IP
```

# Databricks Tracking Server Details

Promote a model across environments by [copying the model](https://docs.databricks.com/en/machine-learning/manage-model-lifecycle/upgrade-workflows.html#promote-a-model-across-environments) version to a new location.

```python
import mlflow
mlflow.set_registry_uri("databricks-uc")

client = mlflow.tracking.MlflowClient()
src_model_name = "staging.ml_team.fraud_detection"
src_model_version = "1"
src_model_uri = f"models:/{src_model_name}/{src_model_version}"
dst_model_name = "prod.ml_team.fraud_detection"
copied_model_version = client.copy_model_version(src_model_uri, dst_model_name)

# Mark model for deployment using aliases
client = mlflow.tracking.MlflowClient()
client.set_registered_model_alias(name="prod.ml_team.fraud_detection", alias="Champion", version=copied_model_version.version)
```

[Use job webhooks to notify external CI/CD systems](https://docs.databricks.com/en/machine-learning/manage-model-lifecycle/upgrade-workflows.html#use-job-webhooks-for-manual-approval-for-model-deployment)

# References

- Databricks - Configure System Notifications https://docs.databricks.com/en/workflows/jobs/job-notifications.html#configure-system-notifications
