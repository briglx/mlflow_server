# pylint: disable=R0801
"""Scoring script for the Online Endpoint."""

import json
import logging
import os

from azureml.ai.monitoring import Collector
import joblib
import numpy

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def init():
    """Inatialize the model."""
    # pylint: disable=W0601
    global model, inputs_collector, outputs_collector
    # AZUREML_MODEL_DIR is an environment variable created during deployment.
    # It is the path to the model folder (./azureml-models/$MODEL_NAME/$VERSION)
    model_path = os.path.join(os.getenv("AZUREML_MODEL_DIR"), "model.pkl")
    # deserialize the model file back into a sklearn model
    model = joblib.load(model_path)
    inputs_collector = Collector(name="model_inputs")
    outputs_collector = Collector(name="model_outputs")
    logging.info("Init complete")


def run(raw_data):
    """Score using the model."""
    logging.info("Request received")
    raw_data = '{"data":[[5.1, 3.5, 1.4, 0.2]]}'
    data = json.loads(raw_data)["data"]
    context = inputs_collector.collect(data)
    data = numpy.array(data)
    outputs_collector.collect(data, context)
    result = model.predict(data)
    logging.info("Request processed")
    return result.tolist()
