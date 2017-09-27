#!/usr/bin/env bash

set -eu

cat > resize-opsman-disk/gcpcreds.json <<EOF
${OPSMAN_GCP_CREDFILE_CONTENTS}
EOF

gcloud --project ${OPSMAN_PROJECT} auth activate-service-account --key-file resize-opsman-disk/gcpcreds.json

OPSMAN_EXTERNAL_IP=$(dig +short ${OPSMAN_DOMAIN_OR_IP_ADDRESS})
OPSMAN_DISK_URI=$(gcloud --project ${OPSMAN_PROJECT} compute instances list --filter="networkInterfaces.accessConfigs.natIP=${OPSMAN_EXTERNAL_IP}" --format=json | jq '.[] .disks[] | select ( .boot == true ) .source')
gcloud --project ${OPSMAN_PROJECT} compute disks resize ${OPSMAN_DISK_URI} --zone ${OPSMAN_ZONE1} --size=${OPSMAN_DISK_SIZE}
