#!/bin/bash -ex

set -eu

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCE_JOB_AZS=$(fn_other_azs $OTHER_AZS)

PRODUCT_PROPERTIES=$(
  jq -n \
    --arg root_service_account_json "$ROOT_SERVICE_ACCOUNT_JSON" \
    --arg db_host "$DB_HOST" \
    --arg db_username "$DB_USERNAME" \
    --arg db_password "$DB_PASSWORD" \
    --arg db_port "$DB_PORT" \
    --arg ca_cert "$CA_CERT" \
    --arg client_cert "$CLIENT_CERT" \
    --arg client_key "$CLIENT_KEY" \
    '
    {
      ".properties.root_service_account_json": {
        "value": $root_service_account_json
      },
      ".properties.db_host": {
        "value": $db_host
      },
      ".properties.db_username": {
        "value": $db_username
      },
      ".properties.db_port": {
        "value": $db_port
      },
      ".properties.ca_cert": {
        "value": $ca_cert
      },
      ".properties.client_cert": {
        "value": $client_cert
      },
      ".properties.client_key": {
        "value": $client_key
      },
      ".properties.db_password": {
        "value": $db_password
      }      
    }
    '
)

PRODUCT_NETWORK_CONFIG=$(cat <<-EOF
{
  "singleton_availability_zone": {
    "name": "$SINGLETON_JOB_AZ"
  },
  "other_availability_zones": [
    $BALANCE_JOB_AZS
  ],
  "network": {
    "name": "$NETWORK_NAME"
  }
}
EOF
)

om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
   --skip-ssl-validation \
   --username "${OPSMAN_USERNAME}" \
   --password "${OPSMAN_PASSWORD}" \
   configure-product \
   --product-name $PRODUCT_NAME \
   --product-properties "$PRODUCT_PROPERTIES" \
   --product-network "$PRODUCT_NETWORK_CONFIG"
