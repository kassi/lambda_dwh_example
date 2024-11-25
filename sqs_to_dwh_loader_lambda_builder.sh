
#!/bin/bash
set -euo pipefail
# set -e # Exit immediately on error
# set -u # Exit on undefined variables
# set -x # Print commands and their arguments as they are executed
# set -o pipefail # Exit on failures in piped commands.

# This script is used to build the lambda function for the custom_type sqs loader
mkdir -p build/sqs_to_dwh_lambda_loader
cp src/sqs_to_dwh_lambda_loader/sqs_to_dwh_lambda_loader.py build/sqs_to_dwh_lambda_loader
docker run --platform linux/amd64 --entrypoint "" -v $(pwd):/var/task amazon/aws-lambda-python:3.12 \
  pip install -r src/sqs_to_dwh_lambda_loader/requirements.txt -t build/sqs_to_dwh_lambda_loader --upgrade
