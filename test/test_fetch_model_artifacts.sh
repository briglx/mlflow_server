#!/bin/bash

model_name="test-tracking-quickstart"
version="2"

python ./script/get_model_artifacts.py --model_name "$model_name" --model_version "$version"
