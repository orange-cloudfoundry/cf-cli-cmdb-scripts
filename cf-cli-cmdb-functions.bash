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
    MATCHING_AUDIT_EVENTS=$(cf curl "/v3/service_instances?label_selector=backing_service_instance_guid==${SERVICE_GUID}")
    # Jq does not properly allow controlling exit status, see https://github.com/stedolan/jq/issues/1142#issuecomment-372847390
    # so we test the output explicitly
    if [[ -n $(echo "${MATCHING_SERVICE_INSTANCES}" | jq .resources[].metadata) ]];
    then
        # Recompute the jq output to preserve color escapes
         echo "${MATCHING_SERVICE_INSTANCES}" | jq .resources[].metadata
         return 0
    else
        echo "No metadata defined for service ${SERVICE_NAME}"
        return 1;
    fi
}
export -f cf_labels_service

# $1: service name
function cf_audit_events_from_guid () {
    #set -x

    local SERVICE_GUID=$1;
    if [[ -z "${SERVICE_GUID}" || "${SERVICE_GUID}" == "-h" ]]; then
        read -r -d '' USAGE <<'EOF'
NAME:
   cf_audit_events_from_guid - List all audit events for a given entity guid (service instance, service binding, ...)

USAGE:
   cf_audit_events_from_guid GUID

EXAMPLES:
   cf_audit_events_from_guid 5e906a7a-34e6-4a54-9808-ad465295b12a
EOF

        printf "${USAGE}\n"
        return 1
    fi
    MATCHING_AUDIT_EVENTS=$(cf curl "/v2/events?q=actee:${SERVICE_GUID}")
    # Jq does not properly allow controlling exit status, see https://github.com/stedolan/jq/issues/1142#issuecomment-372847390
    # so we test the output explicitly
    if [[ $(echo "${MATCHING_AUDIT_EVENTS}" | jq .total_results) -gt 0 ]];
    then
        # Recompute the jq output to preserve color escapes
         echo "${MATCHING_AUDIT_EVENTS}" | jq .
         return 0
    else
        echo "No audit events defined for service ${SERVICE_GUID}"
        return 1;
    fi
    #set +x

}
export -f cf_audit_events_from_guid

