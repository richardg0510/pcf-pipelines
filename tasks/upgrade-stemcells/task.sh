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

function main() {
  local cwd
  cwd="${1}"

  if [ -n "$(find ${cwd}/stemcells/ -prune -empty)" ]; then
    echo "No stemcells found."
    exit 0
  fi

  OUTPUT='  [
     {
       "fallback": "Stemcells have been upgraded in the '$(echo $FOUNDATION_NAME | tr -d '\"')' foundation.",
       "color": "#00467F",
       "title": "Stemcells have been upgraded in the '$(echo $FOUNDATION_NAME | tr -d '\"')' foundation.",
       "text": "The following stemcells have been upgraded in the '$(echo $FOUNDATION_NAME | tr -d '\"')' foundation.",
       "fields": [
  '

  for stemcell in ${cwd}/stemcells/*.tgz; do
    printf "Uploading %s to %s ...\n" "${stemcell}" "${OPSMAN_DOMAIN_OR_IP_ADDRESS}"
    om-linux --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
        --skip-ssl-validation \
        --username "${OPSMAN_USERNAME}" \
        --password "${OPSMAN_PASSWORD}" \
        upload-stemcell \
        --stemcell "${stemcell}"

    OUTPUT=$OUTPUT'{
      "title": "Stemcell",
      "value": "'$(echo $stemcell | cut -d: -f2)'",
      "short": false
    },'
  done

  OUTPUT=$(echo "${OUTPUT::-1}")'     ],
       "footer": "Pipeline Success"
     }
  ]'

cat > foundation-text/text <<EOF
  $OUTPUT
EOF
}

main "${PWD}"
