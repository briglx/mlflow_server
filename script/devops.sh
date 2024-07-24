#!/usr/bin/env bash
#########################################################################
# Onboard and manage application on cloud infrastructure.
# Usage: devops.sh [COMMAND]
# Globals:
#
# Commands
#   validate        Validate deployment of common resources.
#   provision       Provision common resources.
#   build_image     Build the images.
#   publish_image   Publish the images to the registry.
#   deploy          Prepare the app and deploy to cloud.
#   delete          Delete the app from cloud.
# Params
#    -s, --subscription     Azure subscription id
#    -n, --name             Image name
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
    echo "  validate        Validate deployment of common resources."
    echo "  provision       Provision common resources."
    echo "  build_image     Build the images."
    echo "  publish_image   Publish the images to the registry."
    echo "  delete          Delete the app from cloud."
    echo "  deploy          Prepare the app and deploy to cloud."
    echo
    echo "Arguments"
    echo "   -s, --subscription     Azure subscription id"
    echo "   -n, --name             Image name"
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
    if [ -z "$registry" ]
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
    if [ -n "$registry" ]
    then
        additional_parameters+=("acrName=$registry")
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
    local dockerfile_path="${PROJ_ROOT_PATH}/online_endpoint/Dockerfile"

    docker build \
        --build-arg "ARTIFACT_PATH=$artifact_path" \
        --build-arg "RELEASE_VERSION=$version" \
        -t "${name}:${version}" \
        -f "${dockerfile_path}" \
        "${PROJ_ROOT_PATH}"

    # All in one
    # az acr build --image "${REGISTRY_LOGIN_SERVER}//devcontainer/${image}:${tag}"" --registry "${REGISTRY_LOGIN_SERVER}" --file "${build_dir}/.devcontainer/Dockerfile" ${build_dir}

}

publish_image(){
    local deployment_name="${name}.PublishImage-${run_date}"
    local dev_tags=("${version}" "dev")
    local release_tags=("${version}" "latest")

    echo "Publishing ${deployment_name} for version ${version} and channel ${channel}"

    if [ "$channel" == "dev" ]
    then
        tags=("${dev_tags[@]}")
    else
        tags=("${release_tags[@]}")
    fi

    # Tag images with extra tags
    for tag in "${tags[@]}"; do
        docker tag "${name}:${version}" "${name}:${tag}"
    done

    # Push Images
    for tag in "${tags[@]}"; do
        docker tag "${name}:${tag}" "${registry}/${namespace}/${name}:${tag}"
        docker push "${registry}/${namespace}/${name}:${tag}"
    done

}

# Globals
PROJ_ROOT_PATH=$(cd "$(dirname "$0")"/..; pwd)
ENV_FILE="${PROJ_ROOT_PATH}/.env"
echo "Project root: $PROJ_ROOT_PATH"

# Argument/Options
LONGOPTS=artifact_path:,subscription:,name:,resource-group:,location:,version:,channel:,registry:,namespace:,help
OPTIONS=a:s:n:g:l:v:c:r:m:h

# Variables
artifact_path="./artifacts/"
name="devcontainers"
subscription=""
registry=""
resource_group=""
namespace="aimodelserving"
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
        -r|--registry)
            registry="$2"
            shift 2
            ;;
        -m|--namespace)
            namespace="$2"
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
