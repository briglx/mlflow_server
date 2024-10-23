#!/bin/bash

# Enable strict mode.
set -euo pipefail

echo "CONDAPATH environment variable: $CONDAPATH"
echo
conda info -e
echo
echo "Pip Dependencies"
pip freeze

CONDA_ENV_NAME=userenv
# ... Run whatever commands ...

# Temporarily disable strict mode and activate conda:
set +euo pipefail
conda activate $CONDA_ENV_NAME

echo "Pip Dependencies in environment $CONDA_ENV_NAME"
pip freeze

# Re-enable strict mode:
set -euo pipefail

echo "Starting azmlinfsrv with entry script  /tmp/score.py..."
azmlinfsrv --entry_script /tmp/score.py --port 31311
