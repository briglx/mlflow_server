"""Deploy a model to an Azure Machine Learning managed online endpoint."""

# pylint: disable=R0801
import argparse
import os
import random

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
from utils import configure_logging

load_dotenv()

logger = configure_logging("register_model.log")


def main():
    """Deploy a model to an Azure Machine Learning managed online endpoint."""
    logger.info("Deploy model %s to Azure Machine Learning", MODEL_NAME)

    endpoint_name = f"endpt-{random.randint(100000, 99999)}"

    # pylint: disable=R6103
    credential = DefaultAzureCredential()
    if not credential:
        credential = ClientSecretCredential(
            tenant_id=AZURE_TENANT_ID,
            client_id=AZURE_CLIENT_ID,
            client_secret=AZURE_CLIENT_SECRET,
        )
    ml_client = MLClient(
        credential, AZURE_SUBSCRIPTION_ID, AZURE_ML_RESOURCE_GROUP, AZURE_ML_WORKSPACE
    )

    # Create a managed online endpoint
    endpoint = ManagedOnlineEndpoint(
        name=endpoint_name,
        description="Custom image endpoint",
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
    parser = argparse.ArgumentParser(
        description="Register AML Model.",
        add_help=True,
    )
    parser.add_argument(
        "--tenant_id",
        "-t",
        help="Azure Tenant Id where AML workspace is created",
    )
    parser.add_argument(
        "--subscription_id",
        "-s",
        help="Azure Subscription Id where AML workspace is created",
    )
    parser.add_argument(
        "--resource_group",
        "-g",
        help="Azure Resource Group where AML workspace is created",
    )
    parser.add_argument(
        "--workspace",
        "-w",
        help="Azure Machine Learning Workspace Name",
    )
    parser.add_argument(
        "--model_name",
        "-n",
        help="Model Name",
    )
    parser.add_argument(
        "--artifact_path",
        "-a",
        help="Local path to the model artifacts",
    )
    parser.add_argument(
        "--client_id",
        "-c",
        help="Azure Client Id with access to AML workspace",
    )
    parser.add_argument(
        "--client_secret",
        "-p",
        help="Azure Client Secret with access to AML workspace",
    )

    args = parser.parse_args()

    AZURE_TENANT_ID = args.tenant_id or os.environ.get("AZURE_TENANT_ID")
    AZURE_SUBSCRIPTION_ID = args.subscription_id or os.environ.get(
        "AZURE_SUBSCRIPTION_ID"
    )
    AZURE_ML_RESOURCE_GROUP = args.resource_group or os.environ.get(
        "AZURE_ML_RESOURCE_GROUP"
    )
    AZURE_ML_WORKSPACE = args.workspace or os.environ.get("AZURE_ML_WORKSPACE")
    MODEL_NAME = args.model_name or os.environ.get("MODEL_NAME")
    ARTIFACT_PATH = args.artifact_path or os.environ.get("ARTIFACT_PATH")
    AZURE_CLIENT_ID = args.client_id or os.environ.get("AZURE_CLIENT_ID")
    AZURE_CLIENT_SECRET = args.client_secret or os.environ.get("AZURE_CLIENT_SECRET")

    if not AZURE_TENANT_ID:
        raise ValueError("Azure tenant id is required. Have you set AZURE_TENANT_ID?")

    if not AZURE_SUBSCRIPTION_ID:
        raise ValueError(
            "Azure subscription id is required. Have you set AZURE_SUBSCRIPTION_ID?"
        )

    if not AZURE_ML_RESOURCE_GROUP:
        raise ValueError(
            "Azure resource group is required. Have you set AZURE_ML_RESOURCE_GROUP?"
        )

    if not AZURE_ML_WORKSPACE:
        raise ValueError(
            "Azure ML workspace is required. Have you set AZURE_ML_WORKSPACE?"
        )

    if not MODEL_NAME:
        raise ValueError("Model name is required. Have you set MODEL_NAME?")

    if not ARTIFACT_PATH:
        raise ValueError("Artifact path is required. Have you set ARTIFACT_PATH?")

    main()
