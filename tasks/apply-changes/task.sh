#!/bin/bash

set -eu

# Copyright 2017-Present Pivotal Software, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "Applying changes on Ops Manager @ ${OPSMAN_DOMAIN_OR_IP_ADDRESS}"

om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
     --skip-ssl-validation \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
      curl -path /api/v0/staged/pending_changes > changes-status.txt

if [[ $? -ne 0 ]]; then
  echo "Could not login to ops man"
  cat changes-status.txt
  exit 1
fi

grep "action" changes-status.txt
ACTION_STATUS=$?

if [[ ${ACTION_STATUS} -ne 0 && ${RUNNING_STATUS} -ne 0 ]]; then
    echo "No pending changes to apply - exiting..."
    exit 0
fi
      
om-linux \
  --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
  --skip-ssl-validation \
  --username "${OPSMAN_USERNAME}" \
  --password "${OPSMAN_PASSWORD}" \
  apply-changes \
  --ignore-warnings
