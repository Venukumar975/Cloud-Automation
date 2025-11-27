#!/bin/bash

set -e

CONFIG_FILE="./config.json"
PROJECT_NAME=${PROJECT_NAME:-"hosting-template"}

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ config.json not found!"
  exit 1
fi

echo "📘 Reading config.json..."

# Extract backend service key (only one for now)
SERVICE=$(jq -r '.apps.backend | keys[0]' "$CONFIG_FILE")
APP_ENV_LIST=$(jq -r ".apps.backend[\"$SERVICE\"][\"app-env\"][]" "$CONFIG_FILE")

echo "🔧 Backend service: $SERVICE"
echo "🔐 App-specific env vars to collect:"
echo "$APP_ENV_LIST"
echo ""

for KEY in $APP_ENV_LIST; do
  read -p "Enter value for $KEY: " VALUE

  if [ -z "$VALUE" ]; then
    echo "⚠️ Skipping $KEY (no value entered)"
    continue
  fi

  PARAM="/$PROJECT_NAME/backend/env/$KEY"
  echo "➡️ Saving $KEY to SSM Parameter Store ($PARAM)"

  aws ssm put-parameter \
    --name "$PARAM" \
    --value "$VALUE" \
    --type "SecureString" \
    --overwrite >/dev/null

  echo "✔️ Saved to SSM"
done

echo ""
echo "✨ All app-specific environment variables stored securely in SSM."
