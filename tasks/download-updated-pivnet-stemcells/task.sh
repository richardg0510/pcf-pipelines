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
  if [ -z "$API_TOKEN" ]; then abort "The required env var API_TOKEN was not set for pivnet"; fi
  if [ -z "$IAAS_TYPE" ]; then abort "The required env var IAAS_TYPE was not set"; fi

  local cwd=$PWD
  local download_dir="${cwd}/stemcells"
  local diag_report="${cwd}/diagnostic-report/exported-diagnostic-report.json"

  pivnet-cli login --api-token="$API_TOKEN"
  pivnet-cli eula --eula-slug=pivotal_software_eula >/dev/null

  # get the deduplicated stemcell filename for each deployed release (skipping p-bosh)
  local stemcells=($( (jq --raw-output '.added_products.deployed[] | select (.name | contains("p-bosh") | not) | .stemcell' | sort -u) < "$diag_report"))
  if [ ${#stemcells[@]} -eq 0 ]; then
    echo "No installed products found that require a stemcell"
    exit 0
  fi

  mkdir -p "$download_dir"

  # extract the major stemcell version from the filename, e.g. 3312.21, find the latest dot version for that major, and download the file from pivnet
  for stemcell in "${stemcells[@]}"; do
    local current_stemcell_version
    current_stemcell_version=$(echo $(echo "$stemcell" | grep -Eo "[0-9]+(\.[0-9]+)?") | cut -d ' ' -f1)

    local stemcell_major_version
    stemcell_major_version=$(echo $(echo "$stemcell" | grep -Eo "[0-9]+(\.[0-9]+)?") | cut -d. -f1)

    local upgrade_stemcell_version
    upgrade_stemcell_version=$(pivnet releases -p stemcells | grep -v + | grep -v VERSION | awk -F\| '{print $3}' | sed -e "s/ //g" | awk '$1 ~ /^'"$stemcell_major_version"'/' | awk 'NR==1{print $1}')
    if [ "$upgrade_stemcell_version" != "" ] && [ "$upgrade_stemcell_version" != "$current_stemcell_version" ]; then
      download_stemcell_version $upgrade_stemcell_version
    else
      upgrade_stemcell_version=$(pivnet releases -p stemcells-windows-server | grep -v + | grep -v VERSION | awk -F\| '{print $3}' | sed -e "s/ //g" | awk '$1 ~ /^'"$stemcell_major_version"'/' | awk 'NR==1{print $1}')
      if [ "$upgrade_stemcell_version" != "" ] && [ "$upgrade_stemcell_version" != "$current_stemcell_version" ]; then
        download_stemcell_version_windows $upgrade_stemcell_version
      fi
    fi

    echo -------------------------------
  done
}

function abort() {
  echo "$1"
  exit 1
}

function download_stemcell_version() {
  local stemcell_version
  stemcell_version="$1"

  # ensure the stemcell version found in the manifest exists on pivnet
  if [[ $(pivnet-cli pfs -p stemcells -r "$stemcell_version") == *"release not found"* ]]; then
    abort "Could not find the required stemcell version ${stemcell_version}. This version might not be published on PivNet yet, try again later."
  fi

  # loop over all the stemcells for the specified version and then download it if it's for the IaaS we're targeting
  for product_file_id in $(pivnet-cli pfs -p stemcells -r "$stemcell_version" --format json | jq .[].id); do
    local product_file_name
    product_file_name=$(pivnet-cli product-file -p stemcells -r "$stemcell_version" -i "$product_file_id" --format=json | jq .name)
    if echo "$product_file_name" | grep -iq "$IAAS_TYPE"; then
      pivnet-cli download-product-files -p stemcells -r "$stemcell_version" -i "$product_file_id" -d "$download_dir" --accept-eula
      return 0
    fi
  done

  # shouldn't get here
  abort "Could not find stemcell ${stemcell_version} for ${IAAS_TYPE}. Did you specify a supported IaaS type for this stemcell version?"
}

function download_stemcell_version_windows() {
  local stemcell_version
  stemcell_version="$1" | cut -d ' ' -f1

  # ensure the stemcell version found in the manifest exists on pivnet
  if [[ $(pivnet-cli pfs -p stemcells-windows-server -r "$stemcell_version") == *"release not found"* ]]; then
    abort "Could not find the required stemcell version ${stemcell_version}. This version might not be published on PivNet yet, try again later."
  fi

  # loop over all the stemcells for the specified version and then download it if it's for the IaaS we're targeting
  for product_file_id in $(pivnet-cli pfs -p stemcells-windows-server -r "$stemcell_version" --format json | jq .[].id); do
    local product_file_name
    product_file_name=$(pivnet-cli product-file -p stemcells-windows-server -r "$stemcell_version" -i "$product_file_id" --format=json | jq .name)

    local iaas_type_win
    iaas_type_win=$IAAS_TYPE
    if echo "$iaas_type_win" | grep -iq "google"; then
      iaas_type_win="GCP"
    fi

    if echo "$product_file_name" | grep -iq "$iaas_type_win"; then
      pivnet-cli download-product-files -p stemcells-windows-server -r "$stemcell_version" -i "$product_file_id" -d "$download_dir" --accept-eula
      return 0
    fi
  done

  # shouldn't get here
  abort "Could not find stemcell ${stemcell_version} for ${IAAS_TYPE}. Did you specify a supported IaaS type for this stemcell version?"
}

main
