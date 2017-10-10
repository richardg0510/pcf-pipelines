#!/bin/bash -ex

set -eu

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCE_JOB_AZS=$(fn_other_azs $OTHER_AZS)

PRODUCT_PROPERTIES=$(cat <<-EOF
{
  ".properties.firehose_endpoint": {
    "value": "$FIREHOSE_ENDPOINT"
  },
  ".properties.firehose_endpoint": {
    "value": "$FIREHOSE_EVENTS"
  },
  ".properties.firehose_endpoint": {
    "value": "$FIREHOSE_USERNAME"
  },
  ".properties.firehose_endpoint": {
    "value": "$FIREHOSE_PASSWORD"
  },
  ".properties.firehose_endpoint": {
    "value": "$FIREHOSE_SKIP_SSL"
  },
  ".properties.firehose_endpoint": {
    "value": "$SERVICE_ACCOUNT"
  },
  ".properties.firehose_endpoint": {
    "value": "$PROJECT_ID"
  },
}
EOF
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
