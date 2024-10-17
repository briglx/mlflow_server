"""Deploy a model to an Azure Machine Learning managed online endpoint."""

import os

from azure.ai.ml import MLClient
from azure.ai.ml.entities import (
    DataCollector,
    DeploymentCollection,
    Environment,
    ManagedOnlineDeployment,
    ManagedOnlineEndpoint,
)
from azure.identity import ClientSecretCredential, DefaultAzureCredential
from dotenv import load_dotenv

# pylint: disable=W0104
load_dotenv

# Azure General
AZURE_TENANT_ID = os.environ.get("AZURE_TENANT_ID")
AZURE_SUBSCRIPTION_ID = os.environ.get("AZURE_SUBSCRIPTION_ID")
AZURE_CLIENT_ID = os.environ.get("AZURE_CLIENT_ID")
AZURE_CLIENT_SECRET = os.environ.get("AZURE_CLIENT_SECRET")

# AML
AZURE_ML_RESOURCE_GROUP = os.environ.get("AZURE_ML_RESOURCE_GROUP")
AZURE_ML_WORKSPACE = os.environ.get("AZURE_ML_WORKSPACE")


def get_credentials():
    """Get Azure credentials."""
    # pylint: disable=R6103
    credential = DefaultAzureCredential()
    if not credential:
        credential = ClientSecretCredential(
            tenant_id=AZURE_TENANT_ID,
            client_id=AZURE_CLIENT_ID,
            client_secret=AZURE_CLIENT_SECRET,
        )

    return credential


def main():
    """Deploy a model to an Azure Machine Learning managed online endpoint."""
    credential = get_credentials()
    ml_client = MLClient(
        credential, AZURE_SUBSCRIPTION_ID, AZURE_ML_RESOURCE_GROUP, AZURE_ML_WORKSPACE
    )

    endpoint = ManagedOnlineEndpoint(
        name="my_endpoint",
        description="My endpoint description",
        auth_mode="key",
        public_network_access="disabled",
    )

    model = ml_client.models.get(
        name="dev.mlflow-sample-model-test_script", version="4"
    )

    # Configure Data Collection to point to Databricks Storage
    dbx_input_data = ml_client.data.get("my_data_input_asset_id", version=1)
    dbx_output_data = ml_client.data.get("my_data_output_asset_id", version=1)

    inputs_collection = DeploymentCollection(enabled=True, data=dbx_input_data)
    outputs_collection = DeploymentCollection(enabled=True, data=dbx_output_data)

    dbx_data_collector = DataCollector(
        collections={"inputs": inputs_collection, "outputs": outputs_collection}
    )

    # Configure Customer Docker image
    environment = Environment(
        image="docker.io/tensorflow/serving:latest",
        inference_config={
            "liveness_route": {"port": 8501, "path": "/v1/models/half_plus_two"},
            "readiness_route": {"port": 8501, "path": "/v1/models/half_plus_two"},
            "scoring_route": {"port": 8501, "path": "/v1/models/half_plus_two:predict"},
        },
    )

    deployment = ManagedOnlineDeployment(
        name="my_deployment",
        description="My deployment description",
        model=model,
        environment=environment,
        # code_configuration=code_configuration,
        data_collector=dbx_data_collector,
    )

    endpont_create_result = ml_client.begin_create_or_update(endpoint).result()
    deployment_result = ml_client.begin_create_or_update(deployment).result()

    print(f"Endpoint: {endpont_create_result}, Deployment: {deployment_result}")


if __name__ == "__main__":
    main()
