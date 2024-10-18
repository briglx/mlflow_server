"""This module provides a simple scoring service for Azure Machine Learning."""

import time


def init():
    """Inatialize the model."""
    time.sleep(1)


def run(input_data):
    """Score using the model."""
    # Call the model
    return {"message": "Hello, World!", "input_data": input_data}
