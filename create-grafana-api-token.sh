#!/bin/bash

GRAFANA_URL="http://localhost:3001"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"
SERVICE_ACCOUNT_NAME="experiment-executor"
SERVICE_ACCOUNT_ROLE="Admin"
TOKEN_NAME="experiment-executor-token"
TOKEN_FILE="/Users/p371728/Desktop/token.txt"

create_grafana_service_account() {
    local response http_code
    response=$(curl -s -w "%{http_code}" -o /tmp/response.json -u "$ADMIN_USER:$ADMIN_PASSWORD" \
      -H "Content-Type: application/json" \
      -X POST "$GRAFANA_URL/api/serviceaccounts" \
      -d "{\"name\": \"$SERVICE_ACCOUNT_NAME\", \"role\": \"$SERVICE_ACCOUNT_ROLE\"}")

    http_code="${response: -3}"

    if [ "$http_code" -eq 201 ]; then
        local service_account_id
        service_account_id=$(jq -r '.id' /tmp/response.json)
        if [ -n "$service_account_id" ]; then
            echo "$service_account_id"
        else
            echo "Failed to parse service account ID." >&2
            return 1
        fi
    else
        echo "Failed to create service account: $http_code - $(cat /tmp/response.json)" >&2
        return 1
    fi
}

create_grafana_api_token() {
    local service_account_id="$1"
    local response http_code
    response=$(curl -s -w "%{http_code}" -o /tmp/response.json -u "$ADMIN_USER:$ADMIN_PASSWORD" \
      -H "Content-Type: application/json" \
      -X POST "$GRAFANA_URL/api/serviceaccounts/$service_account_id/tokens" \
      -d "{\"name\": \"$TOKEN_NAME\"}")

    http_code="${response: -3}"

    if [ "$http_code" -eq 200 ]; then
        local token
        token=$(jq -r '.key' /tmp/response.json)
        if [ -n "$token" ]; then
            echo "$token"
        else
            echo "Failed to parse API token." >&2
            return 1
        fi
    else
        echo "Failed to create API token: $http_code - $(cat /tmp/response.json)" >&2
        return 1
    fi
}

save_token() {
    local token="$1"
    if [ -n "$token" ]; then
        export GRAFANA_API_TOKEN="$token"
        echo "Token saved to environment variable GRAFANA_API_TOKEN."
        mkdir -p "$(dirname "$TOKEN_FILE")"
        echo "$token" > "$TOKEN_FILE"
        echo "Token saved to file: $TOKEN_FILE"
    else
        echo "No token to save." >&2
        return 1
    fi
}

main() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: 'jq' is required but not installed." >&2
        exit 1
    fi

    echo "Creating Grafana service account..."
    local service_account_id
    service_account_id=$(create_grafana_service_account)
    if [ $? -ne 0 ]; then
        exit 1
    fi

    echo "Creating API token for service account ID $service_account_id..."
    local token
    token=$(create_grafana_api_token "$service_account_id")
    if [ $? -ne 0 ]; then
        exit 1
    fi

    echo "Saving token..."
    save_token "$token"
}

main
