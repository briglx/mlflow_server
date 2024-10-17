#!/bin/bash

set -e

export ENDPOINT_NAME="iris_model"
export ACR_NAME="crcommon150077523"

export ACR_NAME=$(az ml workspace show --query container_registry -o tsv | cut -d'/' -f9-)

export BASE_PATH=endpoints/online/custom-container/minimal/single-model
export ASSET_PATH=endpoints/online/model-1
