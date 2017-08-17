#!/bin/bash

set -eu

SETUP_ENDPOINT="https://$OPS_MGR_HOST/setup"

printf "Connecting to $SETUP_ENDPOINT"
until $(curl --output /dev/null -k --silent --head --fail $SETUP_ENDPOINT); do
    printf '.'
    sleep 5
done

om-linux \
  --target https://$OPS_MGR_HOST \
  --skip-ssl-validation \
  configure-authentication \
  --username $OPS_MGR_USR \
  --password $OPS_MGR_PWD \
  --decryption-passphrase $OM_DECRYPTION_PWD
