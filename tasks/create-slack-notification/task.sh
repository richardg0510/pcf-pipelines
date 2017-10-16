#!/bin/bash

set -eu

release_id=$(cat pivnet-product/metadata.json | jq .Release.ID)
release_version=$(cat pivnet-product/metadata.json | jq .Release.Version)
release_date=$(cat pivnet-product/metadata.json | jq .Release.ReleaseDate)
release_description=$(cat pivnet-product/metadata.json | jq .Release.Description)
release_notes=$(cat pivnet-product/metadata.json | jq .Release.ReleaseNotesURL)

cat > notification-text/text <<EOF
  [
    {
      "fallback": "$(echo $PRODUCT_FRIENDLY_NAME | tr -d '\"') has been upgraded in the $(echo $FOUNDATION_NAME | tr -d '\"') foundation.",
      "color": "#00ff00",
      "title": "Upgrade Pipeline Success - $(echo $PRODUCT_FRIENDLY_NAME | tr -d '\"')",
      "text": "$(echo $PRODUCT_FRIENDLY_NAME | tr -d '\"') has been upgraded in the $(echo $FOUNDATION_NAME | tr -d '\"') foundation.",
      "fields": [
        {
          "title": "Release",
          "value": "$(echo $release_id)",
          "short": false
        },
        {
          "title": "Version",
          "value": "$(echo $release_version | tr -d '\"')",
          "short": false
        },
        {
          "title": "Release Date",
          "value": "$(echo $release_date | tr -d '\"')",
          "short": false
        },
        {
          "title": "Description",
          "value": "$(echo $release_description | tr -d '\"')",
          "short": false
        },
        {
          "title": "Release Notes",
          "value": "$(echo $release_notes | tr -d '\"')",
          "short": false
        }
      ],
      "footer": "Pipeline Success"
    }
  ]
EOF
