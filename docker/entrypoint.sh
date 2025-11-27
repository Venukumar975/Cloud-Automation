#!/bin/sh
python3 /workspace/scripts/generate_tfvars.py /workspace/platform-config.yaml > /workspace/infra/env/prod/terraform.tfvars

cd /workspace/infra/env/prod
terraform init
terraform plan -out tfplan

echo "Apply infrastructure changes? (yes/no)"
read CONFIRM
[ "$CONFIRM" = "yes" ] && terraform apply tfplan || echo "Aborted!"
