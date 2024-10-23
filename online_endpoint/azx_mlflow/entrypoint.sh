#!/bin/bash


SCRIPT_PATH=$(dirname $(realpath -s "$0"))

# Error handling that sleeps so logs are properly sent
handle_error () {
  echo "Error occurred. Sleeping to send error logs."
  # Sleep 45 seconds
  sleep 45
  exit 95
}

format_print () {
    echo "$(date -uIns) | gunicorn/run | $1"
}

echo "$(date -uIns) - start_server.sh $*"

format_print ""
format_print "######################################################"
format_print "Custom Container extending AzureML Runtime Information"
format_print "######################################################"
format_print ""


if [[ -z "${AZUREML_CONDA_ENVIRONMENT_PATH}" ]]; then
    echo "No AZUREML_CONDA_ENVIRONMENT_PATH found."
else
    echo "AZUREML_CONDA_ENVIRONMENT_PATH found. at $AZUREML_CONDA_ENVIRONMENT_PATH"
fi
