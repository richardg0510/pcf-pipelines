#!/bin/bash -ex

set -eu

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCE_JOB_AZS=$(fn_other_azs $OTHER_AZS)

PROPERTIES_CONFIG=$(cat <<-EOF
{
  ".deploy-service-broker.broker_max_instances": {
    "value": "$BROKER_MAX_INSTANCES"
  },
  ".deploy-service-broker.buildpack": {
    "value": "$BUILDPACK"
  },
  ".deploy-service-broker.disable_cert_check": {
    "value": "$DISABLE_CERT_CHECK"
  },
  ".deploy-service-broker.instances_app_push_timeout": {
    "value": "$APP_PUSH_TIMEOUT"
  },
  ".register-service-broker.enable_global_access": {
    "value": "$ENABLE_GLOBAL_ACCESS"
  }
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
  },
  "service_network": {
    "name": "$SERVICES_NETWORK"
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
