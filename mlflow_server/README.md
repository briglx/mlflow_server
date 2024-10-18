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

# Build image
docker build -t "$image_name" -f "${dockerfile_path}" "${project_root}"

# Run container locally
docker run -p 5000:80 "$image_name"

# Interactive shell
docker run -it --entrypoint /bin/bash -p 5000:80  "$image_name"

# Login to the tracking server http://localhost:5000
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

# Tag and Create container app
docker tag "${image_name}" "${AZURE_CONTAINER_REGISTRY_NAME}.azurecr.io/${image_name}"
docker push "${AZURE_CONTAINER_REGISTRY_NAME}.azurecr.io/${image_name}"
response=$(az container create -g "$ACI_RESOURCE_GROUP" --name "mlflowserver" --image "${AZURE_CONTAINER_REGISTRY_NAME}.azurecr.io/${image_name}" --cpu 1 --memory 1 --registry-username "$AZURE_CONTAINER_REGISTRY_USERNAME"  --registry-password "$AZURE_CONTAINER_REGISTRY_PASSWORD" --ip-address Public --ports 80 443)
ip_address=$(echo "$response" | jq -r '.ipAddress.ip')

# Login to the tracking server
echo "MLFlow server running at http://$ip_address"
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
