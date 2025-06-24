#!/bin/bash

TOKEN_RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=$GRANT_TYPE" \
  -d "client_id=$CLIENT_ID" \
  -d "username=$GATLING_USERNAME" \
  -d "password=$GATLING_PASSWORD")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r .access_token)

if [ "$ACCESS_TOKEN" != "null" ] && [ -n "$ACCESS_TOKEN" ]; then
  echo "$ACCESS_TOKEN"
else
  echo "Failed to retrieve token"
  echo "$TOKEN_RESPONSE"
  exit 1
fi
