#!/bin/bash

# Get the directory of the current script
script_dir="$(dirname "$(realpath "$0")")"


model_name="dev.mlflow-sample-model-test_script"
artifact_path="../artifacts/iris_model"

fully_qualified_path="$(realpath "${script_dir}/${artifact_path}")"

python ./script/register_model.py --model_name "$model_name" --artifact_path "$fully_qualified_path"
