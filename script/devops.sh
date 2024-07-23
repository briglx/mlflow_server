#!/usr/bin/env bash
#########################################################################
# Onboard and manage application on cloud infrastructure.
# Usage: devops.sh [COMMAND]
# Globals:
#
# Commands
#   validate    Validate deployment of common resources.
#   provision   Provision common resources.
#   build       Build the images.
#   deploy      Prepare the app and deploy to cloud.
#   delete      Delete the app from cloud.
# Params
#    -s, --subscription     Azure subscription id
#    -n, --name             Registry name
#    -g, --resource-group   Resource group name
#    -h, --help             Show this message and get help for a command.
#    -l, --location         Resource location. Default westus3
#########################################################################

# Stop on errors
set -e

show_help() {
    echo "$0 : Onboard and manage application on cloud infrastructure." >&2
    echo "Usage: devops.sh [COMMAND]"
    echo "Globals"
    echo
    echo "Commands"
    echo "  validate    Validate deployment of common resources."
    echo "  provision   Provision common resources."
    echo "  build       Build the images."
    echo "  delete      Delete the app from cloud."
    echo "  deploy      Prepare the app and deploy to cloud."
    echo
    echo "Arguments"
    echo "   -s, --subscription     Azure subscription id"
    echo "   -n, --name             Registry name"
    echo "   -g, --resource-group   Resource group name"
    echo "   -l, --location         Resource location. Default westus3"
    echo "   -h, --help             Show this message and get help for a command."
    echo
}

validate_general_parameters(){
    # Check command
    if [ -z "$1" ]
    then
        echo "COMMAND is required (provision | deploy)" >&2
        show_help
        exit 1
    fi
}

validate_provision_parameters(){

    # Check SUBSCRIPTION_ID
    if [ -z "$subscription" ]
    then
        echo "subscription is required" >&2
        show_help
        exit 1
    fi

    # Check registry name
    if [ -z "$registry_name" ]
    then
        echo "name is required" >&2
        show_help
        exit 1
    fi

    # Check Resource Group
    if [ -z "$resource_group" ]
    then
        echo "resource-group is required" >&2
        show_help
        exit 1
    fi

}

validate_build_parameters(){

    # Check name
    if [ -z "$name" ]
    then
        echo "name is required" >&2
        show_help
        exit 1
    fi

    # Check version
    if [ -z "$version" ]
    then
        echo "version is required" >&2
        show_help
        exit 1
    fi

    # Check artifact path
    if [ -z "$artifact_path" ]
    then
        echo "artifact_path is required" >&2
        show_help
        exit 1
    fi

}

replace_parameters(){
    # Replace parameters with environment variables
    additional_parameters=()
    if [ -n "$registry_name" ]
    then
        additional_parameters+=("acrName=$registry_name")
    fi
    if [ -n "$resource_group" ]
    then
        additional_parameters+=("rgName=$resource_group")
    fi
    if [ -n "$location" ]
    then
        additional_parameters+=("location=$location")
    fi
    echo "${additional_parameters[@]}"
}

validate_deployment(){
    # Validate Provisioning resources for the application.
    local deployment_name="${name}.Provisioning-${run_date}"

    # Replace parameters
    IFS=' ' read -ra additional_parameters <<< "$(replace_parameters)"

    echo "Validating ${deployment_name} with ${additional_parameters[*]}"

    result=$(az deployment sub validate \
        --subscription "$subscription" \
        --name "${deployment_name}" \
        --location "$location" \
        --template-file "${PROJ_ROOT_PATH}/iac/main.bicep" \
        --parameters "${PROJ_ROOT_PATH}/iac/main.parameters.json" \
        --parameters "${additional_parameters[@]}")

    # Log the validation result
    {
        echo ""
        echo "# Deployment validate results - Generated on ${ISO_DATE_UTC}"
        echo "$result"
    } | tee -a "${PROJ_ROOT_PATH}/.azuredeploy.log"

    state=$(echo "$result" | jq -r '.properties.provisioningState')
    if [ "$state" != "Succeeded" ]
    then
        echo "Deployment failed with state $state"
        echo "$result" | jq -r '.properties.error.details[]'
        exit 1
    fi
    echo "Validation succeeded."

}

provision_common(){
    # Validate Provisioning resources for the application.
    local deployment_name="${name}.Provisioning-${run_date}"

    # Replace parameters
    IFS=' ' read -ra additional_parameters <<< "$(replace_parameters)"

    echo "Deploying ${deployment_name} with ${additional_parameters[*]}"

    result=$(az deployment sub create \
        --subscription "$subscription" \
        --name "${deployment_name}" \
        --location "$location" \
        --template-file "${PROJ_ROOT_PATH}/iac/main.bicep" \
        --parameters "${PROJ_ROOT_PATH}/iac/main.parameters.json" \
        --parameters "${additional_parameters[@]}")

    # Log the validation result
    {
        echo ""
        echo "# Deployment Create results - Generated on ${ISO_DATE_UTC}"
        echo "$result"
    } | tee -a "${PROJ_ROOT_PATH}/.azuredeploy.log"

    state=$(echo "$result" | jq -r '.properties.provisioningState')
    if [ "$state" != "Succeeded" ]
    then
        echo "Deployment failed with state $state"
        echo "$result" | jq -r '.properties.error.details[]'
        exit 1
    fi

    # Get the output variables from the deployment
    output_variables=$(az deployment sub show -n "${deployment_name}" --query 'properties.outputs' --output json)
    echo "Save deployment $deployment_name output variables to ${ENV_FILE}"
    {
        echo ""
        echo "# Script devops - provision command - output variables."
        echo "# Generated on ${ISO_DATE_UTC}"
        echo "$output_variables" | jq -r 'to_entries[] | "\(.key | ascii_upcase )=\(.value.value)"'
    }>> "$ENV_FILE"

}

delete(){
    echo pass
}

build_image(){
    local deployment_name="${name}.Build-${run_date}"
    echo "Building ${deployment_name}"
    # local registry="${registry_name}.azurecr.io"
    # local namespace="devcontainers"
    # # local image_name="$1" #
    # local tag="latest"
    # local release=false
    # local push=false
    # local artifact_path="$1"
    # local artifact_path="${PROJ_ROOT_PATH}/artifacts/"
    local dockerfile_path="${PROJ_ROOT_PATH}/online_endpoint/Dockerfile"
    local image_name="${name}:${version}"

    docker build \
        --build-arg "ARTIFACT_PATH=$artifact_path" \
        --build-arg "RELEASE_VERSION=$version" \
        -t "$image_name" \
        -f "${dockerfile_path}" \
        "${PROJ_ROOT_PATH}"

    # All in one
    # az acr build --image "${REGISTRY_LOGIN_SERVER}//devcontainer/${image}:${tag}"" --registry "${REGISTRY_LOGIN_SERVER}" --file "${build_dir}/.devcontainer/Dockerfile" ${build_dir}

}

push_registry() {
    local repository=${1}
    local image=${2}
    local tag=${3}
    local registry_login_server=${4}

    docker tag "${repository}/${image}:${tag}" "${registry_login_server}/devcontainer/${image}:${tag}"
    docker push "${registry_login_server}/devcontainer/${image}:${tag}"
    # cosign sign --yes "${REGISTRY_LOGIN_SERVER}/devcontainer/${image}:${tag}"
}

publish_image(){
    local deployment_name="${name}.PublishImage-${run_date}"
    local image="$name"
    local dev_tags=("${version}" "dev")
    local release_tags=("${version}" "latest")
    local registry_login_server="${registry_name}.azurecr.io"

    echo "Publishing ${deployment_name} for version ${version} and channel ${channel}"

    if [ "$channel" == "dev" ]
    then
        tags=("${dev_tags[@]}")
    else
        tags=("${release_tags[@]}")
    fi

    # Tag images
    for tag in "${tags[@]}"; do
        docker tag "${repository}/${image}:${version}" "${repository}/${image}:${tag}"
    done

    # Login to Azure Container Registry
    az acr login --name "$registry_name"

    # Push Images
    for tag in "${tags[@]}"; do
        push_registry "${repository}" "${image}" "${tag}" "${registry_login_server}"
    done

}

# Globals
PROJ_ROOT_PATH=$(cd "$(dirname "$0")"/..; pwd)
ENV_FILE="${PROJ_ROOT_PATH}/.env"
echo "Project root: $PROJ_ROOT_PATH"

# Argument/Options
LONGOPTS=artifact_path:,subscription:,name:,resource-group:,repository:,location:,version:,channel:,registry:,help
OPTIONS=a:s:n:g:p:l:v:c:r:h

# Variables
artifact_path="./artifacts/"
name="devcontainers"
subscription=""
registry_name=""
resource_group=""
repository=""
location="westus3"
version="$(date +%Y.%m.0)"
channel="dev"
run_date=$(date +%Y%m%dT%H%M%S)
ISO_DATE_UTC=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# Parse arguments
TEMP=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
eval set -- "$TEMP"
unset TEMP
while true; do
    case "$1" in
        -h|--help)
            show_help
            exit
            ;;
        -n|--name)
            name="$2"
            shift 2
            ;;
        -s|--subscription)
            subscription="$2"
            shift 2
            ;;
        -g|--resource-group)
            resource_group="$2"
            shift 2
            ;;
        -l|--location)
            location="$2"
            shift 2
            ;;
        -v|--version)
            version="$2"
            shift 2
            ;;
        -c|--channel)
            channel="$2"
            shift 2
            ;;
        -p|--repository)
            repository="$2"
            shift 2
            ;;
        -r|--registry)
            registry_name="$2"
            shift 2
            ;;
        -a|--artifact_path)
            artifact_path="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unknown parameters."
            show_help
            exit 1
            ;;
    esac
done

validate_general_parameters "$@"
command=$1
case "$command" in
    validate)
        validate_deployment
        exit 0
        ;;
    provision)
        validate_provision_parameters "$@"
        provision_common
        exit 0
        ;;
    delete)
        delete
        exit 0
        ;;
    build_image)
        validate_build_parameters "$@"
        build_image
        exit 0
        ;;
    publish_image)
        validate_build_parameters "$@"
        publish_image
        exit 0
        ;;
    *)
        echo "Unknown command."
        show_help
        exit 1
        ;;
esac
