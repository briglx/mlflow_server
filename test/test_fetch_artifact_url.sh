#!/bin/bash

user_name="admin"
password="admin"
host="20.168.13.69"
tracking_server="http://${host}:5000"
model_name="test-tracking-quickstart"
version="2"

artifact_uri=$(curl -sS -u "${user_name}:${password}" -L "${tracking_server}/api/2.0/mlflow/model-versions/get-download-uri?name=${model_name}&version=${version}" | jq -r '.artifact_uri')
if [ "$?" -ne 0 ]; then
    echo "Error fetching artifact URI"
    exit 1
else
    echo "${artifact_uri}"
fi
