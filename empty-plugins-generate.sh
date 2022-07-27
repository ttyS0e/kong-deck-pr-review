#!/bin/bash

for API_SPEC in ./api/*.yaml; do
    API_FILE=$(basename $API_SPEC)

    # Create the sample service-level plugin
    API_NAME=$(yq e '.x-kong-name' api/$API_FILE)
    echo -e "_format_version: \"1.1\"\n_workspace: \"rb\"\n_info:\n  select_tags:\n  - sample-api\n\n# plugins:\n# - service: \"$API_NAME\"\n#   name: {plugin_name}\n#   config:\n#     option_1: val\n#     option_2: val" > plugins/$API_FILE

    for OP_ID in $(yq e '.paths.*.*."x-kong-name"' api/echo-server.yaml); do
        echo -e "# - route: \"$OP_ID\"\n#   name: {plugin_name}\n#   config:\n#     option_1: val\n#     option_2: val" >> plugins/$API_FILE
    done
done
