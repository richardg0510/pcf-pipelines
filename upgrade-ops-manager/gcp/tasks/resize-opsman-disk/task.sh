#!/usr/bin/env bash

set -eu

OPSMAN_GCP_CREDFILE="./gcpcreds.json"
OPSMAN_GCP_INSTANCE_INFO="./opsman.json"

cat > ${OPSMAN_GCP_CREDFILE} <<EOF
${OPSMAN_GCP_CREDFILE_CONTENTS}
EOF

gcloud --project ${OPSMAN_PROJECT} auth activate-service-account --key-file ${OPSMAN_GCP_CREDFILE}

OPSMAN_EXTERNAL_IP=$(dig +short ${OPSMAN_DOMAIN_OR_IP_ADDRESS})
gcloud --project ${OPSMAN_PROJECT} compute instances list --filter="networkInterfaces.accessConfigs.natIP=${OPSMAN_EXTERNAL_IP}" --format=json >> ${OPSMAN_GCP_INSTANCE_INFO}
OPSMAN_NAME=$(jq --raw-output '.[] .name' ${OPSMAN_GCP_INSTANCE_INFO})
OPSMAN_DISK_URI=$(jq --raw-output '.[] .disks[] | select ( .boot == true ) .source' ${OPSMAN_GCP_INSTANCE_INFO})
gcloud --project ${OPSMAN_PROJECT} compute disks resize ${OPSMAN_DISK_URI} --zone ${OPSMAN_ZONE} --size=${OPSMAN_DISK_SIZE} --quiet
gcloud --project ${OPSMAN_PROJECT} compute instances reset ${OPSMAN_NAME} --zone ${OPSMAN_ZONE} --quiet
