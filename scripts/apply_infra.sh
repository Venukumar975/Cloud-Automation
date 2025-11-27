#!/bin/bash
set -e

###
# UNIVERSAL PATH FIX (Windows, Mac, Linux)
# - On Windows Git Bash, HOME is wrong -> use USERPROFILE
# - cygpath converts it for Docker to understand
###
if [[ "$OS" == "Windows_NT" ]]; then
  AWS_REAL_HOME="$(cygpath "$USERPROFILE")"
  AWS_REAL_HOME="${AWS_REAL_HOME//\\//}"
  AWS_REAL_HOME="/${AWS_REAL_HOME/:/}"

else
  AWS_REAL_HOME="$HOME"
fi

# Current repo path
WORKSPACE_PATH="$(pwd -W)"

# Verify AWS credentials locally (not inside Docker)
./scripts/check_aws.sh

echo "#############################################################"
echo "Building IaC Docker image..."
docker build -f docker/Dockerfile -t platform-iac docker

echo "#############################################################"
echo "Generating terraform.tfvars inside Docker..."
docker run --rm --entrypoint "" \
  -v "$WORKSPACE_PATH":/workspace \
  -v "$AWS_REAL_HOME/.aws":/root/.aws \
  -e AWS_SDK_LOAD_CONFIG=1 \
  platform-iac \
  sh -c "python3 /workspace/scripts/generate_tfvars.py /workspace/platform-config.yaml" \
  > infra/env/prod/terraform.tfvars

echo "#############################################################"
echo "Applying Terraform..."
docker run --rm --entrypoint "" \
  -v "$WORKSPACE_PATH":/workspace \
  -v "$AWS_REAL_HOME/.aws":/root/.aws \
  -e AWS_SDK_LOAD_CONFIG=1 \
  platform-iac \
  sh -c "
    cd /workspace/infra/env/prod && \
    terraform init && \
    terraform plan -out=tfplan && \
    terraform apply -auto-approve tfplan
  "
echo "...."
echo "Infrastructure deployed successfully!"
