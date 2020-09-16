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
    # Jq does not properly allow controlling exit status, see https://github.com/stedolan/jq/issues/1142#issuecomment-372847390
    # so we test the output explicitly
    if [[ -n $(echo "${MATCHING_SERVICE_INSTANCES}" | jq .resources[].metadata) ]];
    then
        # Recompute the jq output to preserve color escapes
         echo "Metadata for service ${SERVICE_NAME}:"
         echo "${MATCHING_SERVICE_INSTANCES}" | jq .resources[].metadata
         return 0
    else
        echo "No metadata defined for service ${SERVICE_NAME}"
        return 1;
    fi
}
export -f cf_labels_service

# $1: entity guid
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
         echo "Events for service guid ${SERVICE_GUID}:"
         echo "${MATCHING_AUDIT_EVENTS}" | jq .
         return 0
    else
        echo "No audit events defined for service guid ${SERVICE_GUID}. Hint: did they expire and were purged ? Check service instance status date."
        return 1;
    fi
    #set +x

}
export -f cf_audit_events_from_guid

# $1: service name
function cf_audit_events_from_service_name () {
    #set -x

    local SERVICE_NAME=$1;
    if [[ -z "${SERVICE_NAME}" || "${SERVICE_NAME}" == "-h" ]]; then
        read -r -d '' USAGE <<'EOF'
NAME:
   cf_audit_events_from_service_name - List all audit events for a given service instance name

USAGE:
   cf_audit_events_from_service_name service_name

EXAMPLES:
   cf_audit_events_from_service_name my-db
EOF

        printf "${USAGE}\n"
        return 1
    fi

    local SERVICE_NAME MATCHING_SERVICE_INSTANCES
    SERVICE_NAME=$(cf service ${SERVICE_NAME} --guid);
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    cf_audit_events_from_guid $SERVICE_NAME
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    #set +x

}
export -f cf_audit_events_from_service_name



# $1: service name
function cf_service_details () {
    #set -x

    local SERVICE_NAME=$1;
    if [[ -z "${SERVICE_NAME}" || "${SERVICE_NAME}" == "-h" ]]; then
        read -r -d '' USAGE <<'EOF'
NAME:
   cf_service_details - List all details regarding a given service instance name

USAGE:
   cf_service_details service_name

EXAMPLES:
   cf_service_details my-db
EOF

        printf "${USAGE}\n"
        return 1
    fi

    cf service $SERVICE_NAME
    echo
    cf_labels_service $SERVICE_NAME
    echo
    cf_audit_events_from_service_name $SERVICE_NAME
    echo
}
export -f cf_service_details



function cf_org_space_hierarchy() {
    local OPTION=$1;
    if [[ -n "${OPTION}" && "${OPTION}" != "--include-service-instances" || "${OPTION}" == "-h" ]]; then
        read -r -d '' USAGE <<'EOF'
NAME:
   cf_org_space_hierarchy - Display an overview of the cmdb orgs and space as a tree

USAGE:
   cf_org_space_hierarchy [ --include-service-instances ]

EXAMPLES:
   cf_org_space_hierarchy
EOF

        printf "${USAGE}\n"
        return 1
    fi
  local DISPLAY_SERVICE_INSTANCES="false"
  if [[ "${OPTION}" == "--include-service-instances" ]]; then
    DISPLAY_SERVICE_INSTANCES="true"
  fi

  local top_dir="ascii-art-diagrams"
  rm -rf ${top_dir}
  local ORGS=$(cf orgs | grep cmdb | grep -v test)
  for o in $ORGS; do
    cf t -o $o > /dev/null;
    local SPACES=$(cf spaces|tail -n +5);
    local org_dir="$top_dir/$o"
    mkdir -p $org_dir
    for s in $SPACES; do
      local space_dir="$org_dir/$s"
      if [[ $DISPLAY_SERVICE_INSTANCES != "true" ]]; then
        touch $space_dir  # render as a file to get a different color
      else
        mkdir -p $space_dir
        cf t -o $o -s $s > /dev/null;
        local SERVICES_INSTANCES=$(cf services | tail -n +4 | awk '{print $1}');
        for si in $SERVICES_INSTANCES; do
          touch $space_dir/${si}
        done
      fi
    done
  done
  cd ascii-art-diagrams
  tree
  cd ..
  rm -rf ascii-art-diagrams
}
export -f cf_org_space_hierarchy


function cf_cmdb_cli_usage () {
  read -r -d '' USAGE <<'EOF'
NAME:
   cf_cmdb_cli_usage - List osb-cmdb functions registered. Try each with -h to print usage

USAGE:
   cf_cmdb_cli_usage

EXAMPLES:
   cf_cmdb_cli_usage

Registered functions:
EOF

    printf "${USAGE}\n"

  local cmdb_functions="cf_audit_events_from_guid cf_audit_events_from_service_name cf_labels_service cf_service_details cf_org_space_hierarchy"
  for f in $cmdb_functions; do
   $f -h | grep -A1 "NAME:" | grep -v "NAME:"
  done;
}
export -f cf_cmdb_cli_usage