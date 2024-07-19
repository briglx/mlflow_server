# MLFlow Server

Example project to show how to run an MLFlow tracking server and artifact store.

![Architecture Overview](./docs/architecture_overview.svg)

## Provision Server

Create a new VM in Azure and run the following commands to provision the server.

```bash
# Setup virtual environment and install dependencies
./script/setup.sh

# Start Dependencies
docker compose up -d

# Start MLFlow server
./script/start.sh
```

Configure systemd file `/etc/systemd/system/mlflow.service` to start the MLFlow server on boot.

```bash
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

## Tracking Server

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
* Databricks - Configure System Notifications https://docs.databricks.com/en/workflows/jobs/job-notifications.html#configure-system-notifications
