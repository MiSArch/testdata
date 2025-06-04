#!/bin/bash

set -euo pipefail

#echo "⏳ Idling for 120 seconds until MiSArch is ready..."
#sleep 120

echo "🚀 Starting script execution in Docker container..."

# Run the scripts in the desired order
echo "✅ Running create-gatling-user.sh..."
USER_ID=$(/app/create-gatling-user.sh)

echo "✅ Running create-test_data.sh..."
/app/create-test-data.sh "$USER_ID"

echo "✅ Running create-grafana-api-token.sh..."
/app/create-grafana-api-token.sh
