#!/bin/bash

set -euo pipefail

if [[ "${INIT_IDLE:-false}" == "true" ]]; then
  echo "⏳ Idling for 4 minutes until MiSArch is ready..."
  sleep 240
fi

echo "🚀 Starting script execution in Docker container..."

# Run the scripts in the desired order
echo "✅ Running create-gatling-user.sh..."
/app/create-gatling-user.sh

echo "✅ Running create-test_data.sh..."
/app/create-test-data.sh