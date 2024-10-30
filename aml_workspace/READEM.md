# AML Workspace

This folder contains the scripts to provision an Azure Machine Learning workspace.

## Configure Permissions
Azure uses managed identities to access the storage account and the container registry.

```bash
# load .env vars (optional)
[ -f .env ] && while IFS= read -r line; do [[ $line =~ ^[^#]*= ]] && eval "export $line"; done < .env

# AcrPull permission on the workspace container registry.

# Get AML managed identity
identity_id=$(az ml workspace show --resource-group $AZURE_ML_RESOURCE_GROUP --name $AZURE_ML_WORKSPACE --query identity.principal_id -o tsv)

# Get ACR id
acr_id=$(az acr show --name $AZURE_CONTAINER_REGISTRY_NAME --resource-group $AZURE_CONTAINER_REGISTRY_RG_NAME --query id -o tsv)

# Assign AcrPull permission to the managed identity
az role assignment create --assignee $identity_id --role acrpull --scope $acr_id
```


# References
- Troubleshoot https://learn.microsoft.com/en-us/azure/machine-learning/how-to-troubleshoot-online-endpoints?view=azureml-api-2&tabs=cli#authorization-error
