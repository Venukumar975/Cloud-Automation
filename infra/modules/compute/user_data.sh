#!/bin/bash
set -e

# SERVICE="${service_name}"
# PROJECT="${project_name}"
# PORT="${app_port}"
# REGION="${region}"

apt-get update -y
apt-get install -y docker.io awscli
systemctl enable docker
systemctl start docker

IMAGE=$(aws ssm get-parameter \
  --name "/${project_name}/compute/${service_name}/image_uri" \
  --query "Parameter.Value" \
  --output text \
  --region "${region}")

docker pull "$IMAGE"

docker stop app || true
docker rm app || true

docker run -d --name app --restart always -p ${app_port}:${app_port} "$IMAGE"
