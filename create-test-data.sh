#!/bin/bash

set -euo pipefail

GRAPHQL_ENDPOINT="http://gateway:8080/graphql"
AUTH_HEADER="Authorization: Bearer $(./get-token.sh)"

execute_mutation() {
  local mutation="$1"
  local payload
  payload=$(jq -n --arg query "$mutation" '{ query: $query }')

  curl -s -X POST "$GRAPHQL_ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "$AUTH_HEADER" \
    -d "$payload" | jq -r '.data'
}
# 0. Fetch user ID
USER_ID=$(curl -s -X POST "$GRAPHQL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{"query": "{users {nodes {id}}}"}' | jq -r '.data.users.nodes[0].id')

# 1. Create user address
USER_ADDRESS_RESPONSE=$(execute_mutation "mutation { createUserAddress(input:{ city: \"Stuttgart\", companyName: \"University of Stuttgart\", country: \"Germany\", postalCode: \"70569\", street1: \"Universitaetsstrasse\", street2: \"38\", userId: \"$USER_ID\" }) { id } }")
USER_ADDRESS_ID=$(echo "$USER_ADDRESS_RESPONSE" | jq -r '.createUserAddress.id')
echo "✅ User Address ID: $USER_ADDRESS_ID"

# 2. Create tax rate
TAX_RATE_RESPONSE=$(execute_mutation 'mutation { createTaxRate(input: { description: "VAT", initialVersion: { rate: 19.0 }, name: "VAT" }) { id } }')
TAX_RATE_ID=$(echo "$TAX_RATE_RESPONSE" | jq -r '.createTaxRate.id')
echo "✅ Tax Rate ID: $TAX_RATE_ID"

# 3. Create shipment method
SHIPMENT_METHOD_RESPONSE=$(execute_mutation 'mutation { createShipmentMethod(input: { baseFees: 5, description: "DHL rules the world.", externalReference: "", feesPerItem: 1, feesPerKg: 5, name: "DHL" }) { id } }')
SHIPMENT_METHOD_ID=$(echo "$SHIPMENT_METHOD_RESPONSE" | jq -r '.createShipmentMethod.id')
echo "✅ Shipment Method ID: $SHIPMENT_METHOD_ID"

# 4. Create category
CATEGORY_RESPONSE=$(execute_mutation 'mutation { createCategory(input: { categoricalCharacteristics: { name: "Pop", description: "Pop" }, description: "CDs", name: "CDs", numericalCharacteristics: [] }) { id characteristics { nodes { id } } } }')
CATEGORY_ID=$(echo "$CATEGORY_RESPONSE" | jq -r '.createCategory.id')
CHARACTERISTIC_ID=$(echo "$CATEGORY_RESPONSE" | jq -r '.createCategory.characteristics.nodes[0].id')
echo "✅ Category ID: $CATEGORY_ID"
echo "✅ Characteristic ID: $CHARACTERISTIC_ID"

# 5. Create product
PRODUCT_MUTATION=$(cat <<EOF
mutation {
  createProduct(input: {
    categoryIds: ["$CATEGORY_ID"],
    defaultVariant: {
      initialVersion: {
        canBeReturnedForDays: 30,
        categoricalCharacteristicValues: { characteristicId: "$CHARACTERISTIC_ID", value: "CDs" },
        description: "POP 2025",
        name: "POP 2025",
        numericalCharacteristicValues: [],
        retailPrice: 20,
        taxRateId: "$TAX_RATE_ID",
        weight: 0.5,
        mediaIds: []
      },
      isPubliclyVisible: true
    },
    internalName: "POP2025",
    isPubliclyVisible: true
  }) {
    id
    defaultVariant { id }
  }
}
EOF
)

PRODUCT_RESPONSE=$(execute_mutation "$PRODUCT_MUTATION")
PRODUCT_ID=$(echo "$PRODUCT_RESPONSE" | jq -r '.createProduct.id')
PRODUCT_VARIANT_ID=$(echo "$PRODUCT_RESPONSE" | jq -r '.createProduct.defaultVariant.id')
echo "✅ Product ID: $PRODUCT_ID"
echo "✅ Product Variant ID: $PRODUCT_VARIANT_ID"

# 5. Restock product variant
for i in {1..100}; do
  RESTOCK_RESPONSE=$(execute_mutation "mutation { createProductItemBatch(input:{ productVariantId: \"$PRODUCT_VARIANT_ID\", number: 100 }) { id } }")
done
echo "✅ Restocked 10000 items"


echo "🎉 All mutations executed successfully."
