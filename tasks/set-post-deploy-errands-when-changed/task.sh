#!/bin/bash

set -eu

ERRANDS=$(om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
   --skip-ssl-validation \
   --username "${OPSMAN_USERNAME}" \
   --password "${OPSMAN_PASSWORD}" \
   errands \
   --product-name $PRODUCT_NAME \
   | grep -v + \
   | grep -v NAME \
   | awk -F\| '{if ($3 == " true                ") print $2}' \
   | sed -e "s/ //g" \
   | sed -e 'H;${x;s/\n/ /g;s/^ //;p;};d')

for errand in $ERRANDS
 do
   echo "$errand"
   set +e
   ERRAND_EXISTS=$(om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
      --skip-ssl-validation \
      --username "${OPSMAN_USERNAME}" \
      --password "${OPSMAN_PASSWORD}" \
      errands \
      --product-name $PRODUCT_NAME | grep -w "\s$errand\s")

   set -e
   echo $ERRAND_EXISTS

   if [[ ! -z "$ERRAND_EXISTS" ]]; then
     echo $errand " errand found... setting to when-changed..."

     om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
        --skip-ssl-validation \
        --username "${OPSMAN_USERNAME}" \
        --password "${OPSMAN_PASSWORD}" \
        set-errand-state \
        --product-name $PRODUCT_NAME \
        --errand-name "${errand}" \
        --post-deploy-state when-changed
   else
     echo $i " errand not found... skipping..."
   fi
 done
