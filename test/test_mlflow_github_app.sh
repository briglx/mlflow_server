#!/usr/bin/env bash
# ###################################################################
# Call the MLflow GitHub App to trigger the workflow
# ###################################################################

# Stop on errors
set -e

python scripts/mlflow_github_app.py --owner "$REPO_OWNER" --repo "$REPO_NAME" --token "$REPO_TOKEN"
