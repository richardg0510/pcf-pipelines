#!/bin/bash -ex

set -eu

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCE_JOB_AZS=$(fn_other_azs $OTHER_AZS)

PRODUCT_PROPERTIES=$(
  jq -n \
    --arg firehose_endpoint "$FIREHOSE_ENDPOINT" \
    --arg firehose_events "$FIREHOSE_EVENTS" \
    --arg firehose_username "$FIREHOSE_USERNAME" \
    --arg firehose_password "$FIREHOSE_PASSWORD" \
    --arg firehose_skip_ssl "$FIREHOSE_SKIP_SSL" \
    --arg service_account "$SERVICE_ACCOUNT" \
    --arg project_id "$PROJECT_ID" \
    '
    {
      ".properties.firehose_endpoint": {
        "value": $firehose_endpoint
      },
      ".properties.firehose_username": {
        "value": $firehose_username
      },
      ".properties.db_username": {
        "value": $db_username
      },
      ".properties.firehose_password": {
        "value": {
          "secret": $firehose_password
        }
      },
      ".properties.firehose_skip_ssl": {
        "value": $firehose_skip_ssl
      },
      ".properties.service_account": {
        "value": $service_account
      },
      ".properties.project_id": {
        "value": $project_id
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
