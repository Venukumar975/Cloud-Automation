#!/bin/bash
set -euxo pipefail

LOG=/var/log/user-data.log
exec > >(tee -a $LOG) 2>&1

# Install Docker if not present
if ! command -v docker >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y docker.io
  systemctl enable --now docker
fi

# Fetch image and port from SSM
IMAGE_URI=$(aws ssm get-parameter --name "/${project_name}/compute/${service_name}/image_uri" --query "Parameter.Value" --output text 2>/dev/null || echo "")
PORT=$(aws ssm get-parameter --name "/${project_name}/compute/${service_name}/port" --query "Parameter.Value" --output text 2>/dev/null || echo "${app_port}")

if [ -z "$${IMAGE_URI}" ]; then
  echo "No image URI found" >&2
fi

# Retry pulling the container image
RETRIES=5
SLEEP=5

for i in $(seq 1 $${RETRIES}); do
  if docker pull "$${IMAGE_URI}"; then
    echo "Pulled $${IMAGE_URI}"
    break
  fi
  echo "Retry $i failed..."
  sleep $${SLEEP}
  SLEEP=$$((SLEEP * 2))
done

# Remove old container
docker rm -f app || true

# Run container
docker run -d --name app --restart unless-stopped -p $${PORT}:$${PORT} "$${IMAGE_URI}"

# Health path
HEALTH_PATH="${health_path}"
[ -z "$${HEALTH_PATH}" ] && HEALTH_PATH="/health"

# Wait for app to become healthy
for i in {1..20}; do
  if curl -sS --fail "http://localhost:$${PORT}$${HEALTH_PATH}" >/dev/null 2>&1; then
    echo "Application healthy locally"
    exit 0
  fi
  echo "Waiting for health..."
  sleep 6
done

echo "App did not become healthy in time" >&2










































