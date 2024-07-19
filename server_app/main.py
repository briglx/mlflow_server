"""This script triggers a GitHub Actions workflow by sending a repository dispatch event."""

import argparse
import json
import os
import time

from dotenv import load_dotenv
from jwt import JWT, jwk_from_pem
import requests

load_dotenv()


def generate_jwt():
    """
    Generate a JSON Web Token (JWT) using a private key.

    Returns:
        str: The generated JWT.
    """
    pem_relative_path = os.environ.get("PRIVATE_KEY_PATH")

    project_dir = os.path.dirname(os.path.abspath(__file__))
    # Construct the absolute path to the private key file
    pem_path = os.path.join(project_dir, pem_relative_path)

    with open(pem_path, "rb") as pem_file:
        private_key = jwk_from_pem(pem_file.read())

    now = int(time.time())
    payload = {"iat": now, "exp": now + 600, "iss": CLIENT_ID, "alg": "RS256"}

    # Create JWT
    jwt_instance = JWT()
    encrypted = jwt_instance.encode(payload, private_key, alg="RS256")

    if isinstance(encrypted, bytes):
        return encrypted.decode("utf-8")
    return encrypted


def get_access_token():
    """
    Get the access token for the GitHub API.

    Returns:
        str: The access token.
    """
    # Generate a JWT
    jwt_token = generate_jwt()

    # Headers for the request
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {jwt_token}",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    # Get the installation ID
    url = "https://api.github.com/app/installations"
    response = requests.get(url, headers=headers, timeout=10)
    installation_id = response.json()[0]["id"]

    # Get the access token
    url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
    response = requests.post(url, headers=headers, timeout=10)
    access_token = response.json()["token"]
    return access_token


def main():
    """Trigger a GitHub Actions workflow by sending a dispatch event."""
    # Get the access token
    access_token = get_access_token()

    # GitHub API URL for triggering a dispatch event
    url = f"https://api.github.com/repos/{OWNER}/{REPO}/dispatches"

    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Token {access_token}",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    # Payload to send with the request
    payload = {
        "event_type": "register_model",
        "client_payload": {"model_name": MODEL_NAME, "model_version": MODEL_VERSION},
    }

    # Send the POST request
    response = requests.post(url, headers=headers, data=json.dumps(payload), timeout=10)

    # Check the response status
    if response.status_code == 204:
        print("Repository dispatch event triggered successfully.")
    else:
        print(f"Failed to trigger dispatch event: {response.status_code}")
        print(response.text)


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="Trigger GitHub Actions workflow.",
        add_help=True,
    )
    parser.add_argument(
        "--owner",
        "-o",
        help="Repo Owner",
    )
    parser.add_argument(
        "--repo",
        "-r",
        help="Repo Name",
    )
    parser.add_argument(
        "--token",
        "-t",
        help="GitHub token",
    )
    parser.add_argument(
        "--tracking_uri",
        "-u",
        help="MLflow Host",
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

    OWNER = args.owner or os.environ.get("REPO_OWNER")
    REPO = args.repo or os.environ.get("REPO_NAME")
    CLIENT_ID = os.environ.get("GITHUB_APP_CLIENT_ID")
    MODEL_NAME = args.model_name or os.environ.get("MODEL_NAME")
    MODEL_VERSION = args.model_version or os.environ.get("MODEL_VERSION")

    if not OWNER:
        raise ValueError("Owner is required. Have you set the REPO_OWNER env variable?")

    if not REPO:
        raise ValueError(
            "Repo name is required. Have you set the REPO_NAME env variable?"
        )

    if not CLIENT_ID:
        raise ValueError(
            "Client ID is required. Have you set the GITHUB_APP_CLIENT_ID env variable?"
        )

    if not MODEL_NAME:
        raise ValueError(
            "Model Name is required. Have you set the MODEL_NAME env variable?"
        )

    if not MODEL_VERSION:
        raise ValueError(
            "Model Version is required. Have you set the MODEL_VERSION env variable?"
        )

    main()
