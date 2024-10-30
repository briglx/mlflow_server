# Container Registry

Steps to provision and deploy a container registry on Azure Container instances.

```bash
# load .env vars (optional)
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

az login --use-device-code --tenant "$AZURE_TENANT_ID"

# Provision infrastructure
./scripts/devops.sh provision --name "$APP_NAME"
```

# Publish image to Azure Container Registry

```bash
# load .env vars (optional)
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

# Login to remote registry
az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID"
az acr login --name "$AZURE_CONTAINER_REGISTRY_NAME"
docker login -u "$AZURE_CONTAINER_REGISTRY_USERNAME" -p "$AZURE_CONTAINER_REGISTRY_PASSWORD" "${AZURE_CONTAINER_REGISTRY_NAME}.azurecr.io"

registry_host="${AZURE_CONTAINER_REGISTRY_NAME}.azurecr.io"
namespace="$AZURE_CONTAINER_MODEL_NAMESPACE"
image="dev.mlflow-sample-model-test_script_v4"
tag="2024.7.1.dev20240723T1400"

docker tag "${image}:${tag}" "${registry_host}/${namespace}/${image}:${tag}"
docker push "${registry_host}/${namespace}/${image}:${tag}"
# Successfully pushed
```

# Update Github Secrets

Add the following secrets to your GitHub repository:

```bash
registry: ${{ secrets.AZURE_CONTAINER_REGISTRY_NAME }}.azurecr.io
username: ${{ secrets.AZURE_CONTAINER_REGISTRY_USERNAME }}
password: ${{ secrets.AZURE_CONTAINER_REGISTRY_PASSWORD }}
```

# Add Permissions for AML Workspace

Allow the AML workspace to access the Azure Container Registry.

```bash
# load .env vars (optional)
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env


ENDPOINT_IDENTITY=$(az ml endpoint show --name $ENDPOINT_NAME --resource-group $RESOURCE_GROUP --query "identity.principalId" -o tsv)

az role assignment create --assignee $ENDPOINT_IDENTITY --role "AcrPull" --scope $(az acr show --name $AZURE_CONTAINER_REGISTRY_NAME --resource-group $AZURE_CONTAINER_REGISTRY_RG_NAME --query "id" -o tsv)

```
