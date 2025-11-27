#!/bin/bash

CONFIG="config.json"

if [ ! -f "$CONFIG" ]; then
  echo "❌ config.json not found!"
  exit 1
fi

PROJECT=$(jq -r '.project' "$CONFIG")

if [[ "$PROJECT" == "null" || -z "$PROJECT" ]]; then
  echo "❌ project name missing in config.json"
  exit 1
fi

echo "🔐 Project: $PROJECT"
echo "📌 Fetching environment variable requirements..."

# Extract backend secrets only if backend enabled
BACKEND_ENABLED=$(jq -r '.backend.enabled' "$CONFIG")

if [[ "$BACKEND_ENABLED" == "true" ]]; then
  SECRETS=$(jq -r '.backend.env | to_entries[] | select(.value == true) | .key' "$CONFIG")
else
  SECRETS=""
fi

if [[ -z "$SECRETS" ]]; then
  echo "ℹ️ No secrets to collect from user."
  exit 0
fi

echo "🔑 Required secrets:"
echo "$SECRETS"

# Collect & store secrets to SSM
for KEY in $SECRETS; do
  read -p "Enter value for $KEY: " VALUE
  aws ssm put-parameter \
    --name "/$PROJECT/secrets/$KEY" \
    --value "$VALUE" \
    --type SecureString \
    --overwrite > /dev/null

  echo "✔️ Saved $KEY → SSM"
done

echo "🎉 All secrets stored securely!"
