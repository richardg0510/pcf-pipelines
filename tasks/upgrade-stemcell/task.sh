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

stemcell_file=$(echo $(ls stemcell/ -R | grep "\.tgz$"))

stemcell_version=$(
  echo $diagnostic_report |
  jq \
    --arg stemcell_file "$stemcell_file" \
  '.stemcells[] | select(contains($stemcell_file))'
)

if [[ -z "$stemcell_version" ]]; then
  echo "Uploading stemcell $stemcell_file."
  FILE_PATH=`find ./stemcell -name *.tgz`
  om-linux -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS -u $OPS_MGR_USR -p $OPS_MGR_PWD -k upload-stemcell -s $SC_FILE_PATH
else
  echo "Stemcell $stemcell_file already uploaded."
fi
