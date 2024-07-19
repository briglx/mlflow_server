"""Download the artifacts of a model from the MLOps tracking server."""

import argparse
import os

from dotenv import load_dotenv
import mlflow
from mlflow import MlflowClient

load_dotenv()


def get_run_id(model_name, version=None):
    """Get the run_id of the latest or specified version of a model."""
    client = MlflowClient()
    # model_versions = client.get_model_version(model_name, version)

    registered_model = client.get_registered_model(model_name)
    model_versions = registered_model.latest_versions

    if version is None:
        # Get latest if no version is specified
        model_version = model_versions[-1]
        return model_version.run_id

    for model_version in model_versions:
        if model_version.version == version:
            return model_version.run_id

    return None


def main():
    """Download the artifacts of a model from the MLOps tracking server."""
    # Set the local directory to download the artifacts
    project_dir = os.path.dirname("..")
    local_dir = os.path.join(project_dir, "artifacts")

    # Set the tracking server
    mlflow.set_tracking_uri(TRACKING_SERVER)

    try:
        # get the run id of the most recent model
        if run_id := get_run_id(MODEL_NAME, MODEL_VERSION) is None:
            print(f"Run id was not found for {MODEL_NAME} version {MODEL_VERSION}.")
            return

        # Get the artifact uri for the run
        artifact_uri = mlflow.get_run(run_id).info.artifact_uri

        # Get the last part of the artifact_uri
        artifact_last = artifact_uri.split("/")[-1]

        # Download all artifacts from the run
        client = MlflowClient()
        for artifact in mlflow.artifacts.list_artifacts(artifact_uri):
            # Remove overlap between artifact_uri and artifact.path
            relative_artifact_path = artifact.path.replace(artifact_last, "").replace(
                "/", ""
            )
            client.download_artifacts(run_id, relative_artifact_path, local_dir)
            print(f"Artifact downloaded: {relative_artifact_path} in {local_dir}")
    except TypeError as e:
        print(f"Failed to download artifacts: {e}")


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

    main()
