"""Register a model with Azure machine learning MLFlow tracking server."""

import argparse
import os

from azure.ai.ml import MLClient
from azure.identity import ClientSecretCredential
from dotenv import load_dotenv
import mlflow
from utils import configure_logging

load_dotenv()

logger = configure_logging("register_model.log")


def register_model():
    """Register a model with Azure machine learning MLFlow tracking server."""
    logger.info("Registering model %s from %s", MODEL_NAME, ARTIFACT_PATH)

    # Create an AML MLFlow client
    credential = ClientSecretCredential(
        AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET
    )
    ml_client = MLClient(
        credential, AZURE_SUBSCRIPTION_ID, AZURE_ML_RESOURCE_GROUP, AZURE_ML_WORKSPACE
    )

    # Set the tracking URI for the AML tracking server
    azureml_tracking_uri = ml_client.workspaces.get(
        ml_client.workspace_name
    ).mlflow_tracking_uri
    mlflow.set_tracking_uri(azureml_tracking_uri)

    # Register model from the local path
    model = mlflow.register_model(f"file://{ARTIFACT_PATH}", MODEL_NAME)
    logger.info(
        "Model %s version %s registered from %s",
        model.name,
        model.version,
        ARTIFACT_PATH,
    )


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

    if not AZURE_CLIENT_ID:
        raise ValueError("Azure client id is required. Have you set AZURE_CLIENT_ID?")

    if not AZURE_CLIENT_SECRET:
        raise ValueError(
            "Azure client secret is required. Have you set AZURE_CLIENT_SECRET?"
        )

    register_model()
