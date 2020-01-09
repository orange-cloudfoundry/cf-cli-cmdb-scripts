#!/bin/bash

# $1: service name
function cf_labels_service () {
    local SERVICE_NAME=$1;
    if [[ -z "${SERVICE_NAME}" || "${SERVICE_NAME}" == "-h" ]]; then
        read -r -d '' USAGE <<'EOF'
NAME:
   cf_labels_service - List all labels (key-value pairs) for a given service instance

USAGE:
   cf_labels_service SERVICE_INSTANCE_NAME

EXAMPLES:
   cf_labels_service my-mysql
EOF

        printf "${USAGE}\n"
        return 1
    fi
    local SERVICE_GUID MATCHING_SERVICE_INSTANCES
    SERVICE_GUID=$(cf service ${SERVICE_NAME} --guid);
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    MATCHING_SERVICE_INSTANCES=$(cf curl "/v3/service_instances?label_selector=backing_service_instance_guid==${SERVICE_GUID}")
    if [[ -n $(echo "${MATCHING_SERVICE_INSTANCES}" | jq .resources[].metadata) ]];
    then
         echo "${MATCHING_SERVICE_INSTANCES}" | jq .resources[].metadata
         return 0
    else
        echo "No metadata defined for service ${SERVICE_NAME}"
        return 1;
    fi
}
export -f cf_labels_service

