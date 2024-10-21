# MLOps Pipeline Example

Example project implementation of MLOps using Databricks, MLFlow, GitHub Actions, and Azure Machine Learning.

This projects deviates from the standard MLOps process by

- tracking the model artifacts between Databricks and Azure Machine Learning MLFlow artifact registry
- using a custom Docker image to serve the models.

## Architecture Diagram

![Architecture Overview](./docs/architecture_overview.svg)

1. Data Estate - Training data and Endpoint monitoring data
2. Infrastructure and Admin - Provision and manage the infrastructure
3. Model Development - Develop and train models
4. CICD Triggers - Build Model in QA, Register Models, Gated Deployment to Staging and Prod
5. Model Endpoints - Serve models in staging and prod
6. Stage - Smoke test
7. Production Endpoints
8. Monitoring - Monitor model performance
9. Retrain - Detect data drift to trigger retraining
10. Infrastructure Performance - Detect infrastructure performance issues to trigger remediation

# Getting Started

Configure the environment variables. Copy `example.env` to `.env` and update the values

## Create System Identities

The solution use system identities to deploy cloud resources. The following table lists the system identities and their purpose.

| System Identities      | Authentication                                             | Authorization                                                                                                                                                                  | Purpose                                                                                                          |
| ---------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `env.CICD_CLIENT_NAME` | OpenId Connect (OIDC) based Federated Identity Credentials | Subscription Contributor access<br>Microsoft Graph API admin consent Permissions: <ul><li>Directory.ReadWrite.All</li><li>User.Invite.All</li><li>User.ReadWrite.All</li></ul> | Deploy cloud resources: <ul><li>connectivity resources</li><li>Common resources</li></ul><br>Build Docker Images |

```bash
# Configure the environment variables. Copy `example.env` to `.env` and update the values
cp example.env .env
# load .env vars
[ ! -f .env ] || export $(grep -v '^#' .env | xargs)
# or this version allows variable substitution and quoted long values
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

# Login to az. Only required once per install.
az login --tenant $AZURE_TENANT_ID

# Create Azure CICD system identity
./script/create_cicd_sh.sh
# Adds CICD_CLIENT_ID=$created_clientid to .env
```

## Configure GitHub

Create GitHub secrets for storing Azure configuration.

Open your GitHub repository and go to Settings. Select Secrets and then New Secret. Create secrets with values from `.env` for:

- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `CICD_CLIENT_ID`

## Provision Resources

Follow the instructions in each folder to provision resources.

| Resource               | Instructions                                           |
| ---------------------- | ------------------------------------------------------ |
| Container Registry     | [./container_registry](./container_registry/README.md) |
| MLFlow Tracking Server | [./mlflow_server](./mlflow_server/README.md)           |

## Example Workflow

- [Train a model and register the model in MLFlow](./workflow/01_train_model.ipynb)
- Trigger the GitHub Actions workflow to Register the Model in AML model registry
- Trigger the GitHub Action workflow to build and deploy the model serving image
- Test the endpoint with a sample input

# Development

You'll need to set up a development environment if you want to develop a new feature or fix issues. The project uses a docker based devcontainer to ensure a consistent development environment.

- Open the project in VSCode and it will prompt you to open the project in a devcontainer. This will have all the required tools installed and configured.

## Setup local dev environment

If you use the devcontainer image you need to log into the Container registry

```bash
# load .env vars (optional)
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

az login --use-device-code --tenant "$CONTAINER_AZURE_TENANT_ID"
az acr login --name $CONTAINER_REGISTRY_LOGIN_SERVER --username $CONTAINER_TOKEN_NAME --password $CONTAINER_TOKEN_PWD
docker login -u $CONTAINER_TOKEN_NAME -p $CONTAINER_TOKEN_PWD  $CONTAINER_REGISTRY_LOGIN_SERVER
echo $CONTAINER_TOKEN_PWD | docker login --username $CONTAINER_TOKEN_NAME --password-stdin $CONTAINER_REGISTRY_LOGIN_SERVER
```

If you want to develop outside of a docker devcontainer you can use the following commands to setup your environment.

```bash
# Configure the environment variables. Copy example.env to .env and update the values
cp example.env .env

# load .env vars
# [ ! -f .env ] || export $(grep -v '^#' .env | xargs)
# or this version allows variable substitution and quoted long values
# [ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

# Create and activate a python virtual environment
# Windows
# virtualenv \path\to\.venv -p path\to\specific_version_python.exe
# C:\Users\!Admin\AppData\Local\Programs\Python\Python312\python.exe -m venv .venv
# .venv\scripts\activate

# Linux
# virtualenv .venv /usr/local/bin/python3.12
# python3.12 -m venv .venv
# python3 -m venv .venv
python3 -m venv .venv
source .venv/bin/activate

# Update pip
python -m pip install --upgrade pip

# Install dependencies
pip install -r requirements_dev.txt

# Configure linting and formatting tools
sudo apt-get update
sudo apt-get install -y shellcheck
pre-commit install
```

## Style Guidelines

This project enforces quite strict [PEP8](https://www.python.org/dev/peps/pep-0008/) and [PEP257 (Docstring Conventions)](https://www.python.org/dev/peps/pep-0257/) compliance on all code submitted.

We use [Black](https://github.com/psf/black) for uncompromised code formatting.

Summary of the most relevant points:

- Comments should be full sentences and end with a period.
- [Imports](https://www.python.org/dev/peps/pep-0008/#imports) should be ordered.
- Constants and the content of lists and dictionaries should be in alphabetical order.
- It is advisable to adjust IDE or editor settings to match those requirements.

### Use new style string formatting

Prefer [`f-strings`](https://docs.python.org/3/reference/lexical_analysis.html#f-strings) over `%` or `str.format`.

```python
# New
f"{some_value} {some_other_value}"
# Old, wrong
"{} {}".format("New", "style")
"%s %s" % ("Old", "style")
```

One exception is for logging which uses the percentage formatting. This is to avoid formatting the log message when it is suppressed.

```python
_LOGGER.info("Can't connect to the webservice %s at %s", string1, string2)
```

### Testing

Ideally, all code is checked to verify the following:

All the unit tests pass All code passes the checks from the linting tools To run the linters, run the following commands:

```bash
# Use pre-commit scripts to run all linting
pre-commit run --all-files

# Run a specific linter via pre-commit
pre-commit run --all-files codespell

# Run linters outside of pre-commit
codespell .
shellcheck -x ./script/*.sh
```
