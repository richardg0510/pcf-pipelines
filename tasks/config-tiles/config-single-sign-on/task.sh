#!/bin/bash -ex

set -eu

function fn_other_azs {
  local azs_csv=$1
  echo $azs_csv | awk -F "," -v braceopen='{' -v braceclose='}' -v name='"name":' -v quote='"' -v OFS='"},{"name":"' '$1=$1 {print braceopen name quote $0 quote braceclose}'
}

BALANCE_JOB_AZS=$(fn_other_azs $OTHER_AZS)

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

PRODUCT_RESOURCE_CONFIG=$(cat <<-EOF
{
  "deploy-service-broker": {
    "instance_type": {"id": "automatic"},
    "instances": $DEPLOY_SERVICE_BROKER_INSTANCES
  }
}
EOF
)

$CMD -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS -u $OPSMAN_USERNAME -p $OPSMAN_PASSWORD -k configure-product -n $PRODUCT_NAME -pn "$PRODUCT_NETWORK_CONFIG" -pr "$PRODUCT_RESOURCE_CONFIG"
