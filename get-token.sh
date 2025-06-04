#!/bin/bash

KEYCLOAK_URL="http://keycloak:80/keycloak"
REALM="Misarch"
CLIENT_ID="frontend"
USERNAME="gatling"
PASSWORD="123"
GRANT_TYPE="password"

TOKEN_RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=$GRANT_TYPE" \
  -d "client_id=$CLIENT_ID" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r .access_token)

if [ "$ACCESS_TOKEN" != "null" ] && [ -n "$ACCESS_TOKEN" ]; then
  echo "$ACCESS_TOKEN"
else
  echo "Failed to retrieve token"
  echo "$TOKEN_RESPONSE"
  exit 1
fi
