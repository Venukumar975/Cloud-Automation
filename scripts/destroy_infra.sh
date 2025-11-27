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

#current working repo
WORKSPACE_PATH="$(pwd -W)"

echo "#############################################################"
echo "This will delete your AWS infrastructure"
read -p "Type 'destroy' to continue: " CONFIRM

if [ "$CONFIRM" != "destroy" ]; then
  echo "Aborted."
  exit 1
fi

docker run --rm --entrypoint "" \
  -v "$WORKSPACE_PATH":/workspace \
  -v "$AWS_REAL_HOME/.aws":/root/.aws \
  -e AWS_SDK_LOAD_CONFIG=1 \
  platform-iac sh -c "
    cd /workspace/infra/env/prod && \
    terraform destroy -auto-approve
  "
