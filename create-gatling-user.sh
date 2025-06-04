#!/bin/bash

KEYCLOAK_URL="http://keycloak:80/keycloak"
REALM="Misarch"
ADMIN_USER="admin"
ADMIN_PASS="admin"
CLIENT_ID="admin-cli"
GATLING_USERNAME="gatling"
GATLING_PASSWORD="123"

# 1. Get Admin Token
ACCESS_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASS}" \
  -d "grant_type=password" \
  -d "client_id=${CLIENT_ID}" | jq -r .access_token)

# 2. Create the user
USER_ID=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/users" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d '{
        "username": "'"${GATLING_USERNAME}"'",
        "firstName": "'"${GATLING_USERNAME}"'",
        "lastName": "'"${GATLING_USERNAME}"'",
        "enabled": true
      }')

if [[ "$USER_ID" != "201" ]]; then
  echo "User creation failed or already exists"
fi

# 3. Get the user ID
USER_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/users?username=${GATLING_USERNAME}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" | jq -r '.[0].id')

# 4. Set the user's password
curl -s -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/reset-password" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
        "type": "password",
        "value": "'"${GATLING_PASSWORD}"'",
        "temporary": false
      }'

# 5. Get realm roles (e.g., "offline_access" or "user")
ROLES=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/roles" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

# Filter the role(s) you want to assign — e.g., "user"
ROLE_JSON=$(echo $ROLES | jq '[.[] | select(.name == "user")]')

# 6. Assign realm roles to the user
ROLE_NAMES=("buyer" "admin" "employee")
ASSIGN_ROLES=()

for ROLE_NAME in "${ROLE_NAMES[@]}"; do
  ROLE=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/roles/${ROLE_NAME}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}")
  ASSIGN_ROLES+=("$ROLE")
done

# Build JSON array of roles
ROLE_JSON=$(jq -s '.' <<< "${ASSIGN_ROLES[@]}")

# Assign the roles to the user
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/role-mappings/realm" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${ROLE_JSON}"

# 7. Get user ID from Keycloak
USER_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/users?username=${GATLING_USERNAME}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" | jq -r '.[0].id')

# 8. Publish user ID to Dapr pubsub
JSON_PAYLOAD="{\"id\":\"${USER_ID}\",\"username\":\"${GATLING_USERNAME}\",\"firstName\":\"gatling\",\"lastName\":\"gatling\"}"

curl -s -X POST http://user-dapr:3500/v1.0/publish/pubsub/user/user/create \
     -H "Content-Type: application/json" \
     -d "$JSON_PAYLOAD"

if [ -z "$USER_ID" ]; then
  echo "Failed to retrieve user ID for ${GATLING_USERNAME}" >&2
  exit 1
fi

export USER_ID
echo "✅ Gatling user created and role assigned. USER_ID=${USER_ID}"