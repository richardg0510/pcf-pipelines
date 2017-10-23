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

diagnostic_report=$(
  om-linux \
    --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
    --username $OPS_MGR_USR \
    --password $OPS_MGR_PWD \
    --skip-ssl-validation \
    curl --silent --path "/api/v0/diagnostic_report"
)

stemcell=$(
  echo $diagnostic_report |
  jq \
    --arg version "$STEMCELL_VERSION" \
    --arg glob "$IAAS" \
  '.stemcells[] | select(contains($version) and contains($glob))'
)

ls stemcell
