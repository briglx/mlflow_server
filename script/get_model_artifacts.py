"""Download the artifacts of a model from the MLOps tracking server."""

import argparse
import os
from pathlib import Path

from dotenv import load_dotenv
import mlflow
from mlflow import MlflowClient
from utils import configure_logging

load_dotenv()

logger = configure_logging("get_model_artifacts.log")


def download_artifact():
    """Download the artifacts of a model from the MLOps tracking server."""
    logger.info(
        "Downloading %s version %s artifacts from %s",
        MODEL_NAME,
        MODEL_VERSION,
        TRACKING_SERVER,
    )

    current_file = Path(__file__).resolve()
    project_dir = os.path.dirname(current_file.parent)
    artifact_path = os.path.join(project_dir, "artifacts")

    mlflow.set_tracking_uri(TRACKING_SERVER)

    # Set the artifact uri
    model_uri = (
        f"models:/{MODEL_NAME}/{MODEL_VERSION}"  # reference model by version or alias
    )

    # Set the artifact uri from the model class
    client = MlflowClient()
    model_version_info = client.get_model_version(
        name=MODEL_NAME, version=MODEL_VERSION
    )
    model_uri = model_version_info.source

    local_artifacts = mlflow.artifacts.download_artifacts(
        artifact_uri=model_uri, dst_path=artifact_path
    )
    logger.info("Artifacts downloaded to %s", local_artifacts)

    return local_artifacts


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Get Model details.",
        add_help=True,
    )
    parser.add_argument(
        "--tracking_server",
        "-t",
        help="MLOps Tracking Server",
    )
    parser.add_argument(
        "--model_name",
        "-m",
        help="Model Name",
    )
    parser.add_argument(
        "--model_version",
        "-v",
        help="Model Version",
    )

    args = parser.parse_args()

    TRACKING_SERVER = args.tracking_server or os.environ.get("MLFLOW_TRACKING_URI")
    MODEL_NAME = args.model_name or os.environ.get("MODEL_NAME")
    MODEL_VERSION = args.model_version or os.environ.get("MODEL_VERSION")

    local_artifacts_path = download_artifact()

    # pylint: disable=R6103
    if local_artifacts_path:
        print(local_artifacts_path)  # Print the artifact URI to standard output
    else:
        logger.error("Failed to fetch artifact URI")
        print("Failed to fetch artifact URI")
