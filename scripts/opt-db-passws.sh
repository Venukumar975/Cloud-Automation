# /project/backend/env/MYSQL_HOST
# /project/backend/env/MYSQL_USER
# /project/backend/env/MYSQL_PASSWORD
# /project/backend/env/MYSQL_DATABASE
# /project/backend/env/REDIS_HOST
# /project/backend/env/REDIS_PORT

#!/bin/bash

set -e

PROJECT_NAME=${PROJECT_NAME:-"hosting-template"}

# VALUES SHOULD COME FROM TERRAFORM OUTPUT
MYSQL_HOST=$1
MYSQL_USER=$2
MYSQL_PASSWORD=$3
MYSQL_DATABASE=$4

REDIS_HOST=$5
REDIS_PORT=$6

if [ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_PASSWORD" ]; then
  echo "❌ Usage: ./setup-infra-env-vars.sh <mysql_host> <mysql_user> <mysql_password> <mysql_db> <redis_host> <redis_port>"
  exit 1
fi

echo "🔐 Storing infra variables in SSM..."

function put() {
  local NAME=$1
  local VALUE=$2

  aws ssm put-parameter \
    --name "/$PROJECT_NAME/backend/env/$NAME" \
    --value "$VALUE" \
    --type "SecureString" \
    --overwrite >/dev/null

  echo "✔️ Stored $NAME"
}

put "MYSQL_HOST" "$MYSQL_HOST"
put "MYSQL_USER" "$MYSQL_USER"
put "MYSQL_PASSWORD" "$MYSQL_PASSWORD"
put "MYSQL_DATABASE" "$MYSQL_DATABASE"

put "REDIS_HOST" "$REDIS_HOST"
put "REDIS_PORT" "$REDIS_PORT"

echo ""
echo "✨ All infra environment variables stored securely."
