#!/bin/bash

# $1: service name
function cf_labels_service() {
  local SERVICE_NAME=$1
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
  SERVICE_GUID=$(cf service ${SERVICE_NAME} --guid)
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  MATCHING_SERVICE_INSTANCES=$(cf curl "/v3/service_instances?label_selector=backing_service_instance_guid==${SERVICE_GUID}")
  # Jq does not properly allow controlling exit status, see https://github.com/stedolan/jq/issues/1142#issuecomment-372847390
  # so we test the output explicitly
  if [[ -n $(echo "${MATCHING_SERVICE_INSTANCES}" | jq .resources[].metadata) ]]; then
    # Recompute the jq output to preserve color escapes
    echo "Metadata for service ${SERVICE_NAME}:"
    echo "${MATCHING_SERVICE_INSTANCES}" | jq .resources[].metadata
    return 0
  else
    echo "No metadata defined for service ${SERVICE_NAME}"
    return 1
  fi
}
export -f cf_labels_service

# $1: entity guid
function cf_audit_events_from_guid() {
  #set -x

  local SERVICE_GUID=$1
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
  MATCHING_AUDIT_EVENTS=$(cf curl "/v3/audit_events?target_guids=${SERVICE_GUID}")
  # Jq does not properly allow controlling exit status, see https://github.com/stedolan/jq/issues/1142#issuecomment-372847390
  # so we test the output explicitly
  if [[ $(echo "${MATCHING_AUDIT_EVENTS}" | jq .pagination.total_results) -gt 0 ]]; then
    # Recompute the jq output to preserve color escapes
    echo "Audit events for service guid ${SERVICE_GUID}:"
    echo "${MATCHING_AUDIT_EVENTS}" | jq .
    return 0
  else
    echo "No audit events defined for service guid ${SERVICE_GUID}. Hint: did they expire and were purged ? Check service instance status date."
    return 1
  fi
  #set +x

}
export -f cf_audit_events_from_guid

# $1: service name
function cf_audit_events_from_service_name() {
  #set -x

  local SERVICE_NAME=$1
  if [[ -z "${SERVICE_NAME}" || "${SERVICE_NAME}" == "-h" ]]; then
    read -r -d '' USAGE <<'EOF'
NAME:
   cf_audit_events_from_service_name - List all audit events for a given service instance name

USAGE:
   cf_audit_events_from_service_name service_instance_name

EXAMPLES:
   cf_audit_events_from_service_name my-db
EOF

    printf "${USAGE}\n"
    return 1
  fi

  local SERVICE_NAME MATCHING_SERVICE_INSTANCES
  SERVICE_NAME=$(cf service ${SERVICE_NAME} --guid)
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
function cf_usage_events_from_service_name() {
  #set -x

  local SERVICE_NAME="$1"
  if [[ -z "${SERVICE_NAME}" || "${SERVICE_NAME}" == "-h" ]]; then
    read -r -d '' USAGE <<'EOF'
NAME:
   cf_usage_events_from_service_name - List all service events for a given service instance name

USAGE:
   cf_usage_events_from_service_name service_instance_name

EXAMPLES:
   cf_usage_events_from_service_name my-db
EOF

    printf "${USAGE}\n"
    return 1
  fi

  MATCHING_USAGE_EVENTS=$(cf curl '/v3/service_usage_events?per_page=5000' | jq ".resources[] | select(.service_instance.name | contains(\"${SERVICE_NAME}\"))")
  # Jq does not properly allow controlling exit status, see https://github.com/stedolan/jq/issues/1142#issuecomment-372847390
  # so we test the output explicitly
  if [[ $(echo "${MATCHING_USAGE_EVENTS}" | jq length) -gt 0 ]]; then
    # Recompute the jq output to preserve color escapes
    echo "Usage events for service guid ${SERVICE_GUID} (client filtered from last 5,000 last usage events):"
    echo "${MATCHING_USAGE_EVENTS}" | jq .
    return 0
  else
    echo "No usage events defined for service name ${SERVICE_NAME} among last 5,000 last usage events. Hint: did they expire and were purged ? Check service instance status date."
    return 1
  fi
  #set +x

}
export -f cf_usage_events_from_service_name

# $1: service name
function cf_service_details() {
  #set -x

  local SERVICE_NAME=$1
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
  cf_usage_events_from_service_name $SERVICE_NAME
  echo
}
export -f cf_service_details

# $1: selector
# $2: optional --summary option
function cf_services_from_selector() {
  #set -x

  local LABEL_SELECTOR=$1
  local SUMMARY_OPTION=$2
  if [[ -z "${LABEL_SELECTOR}" || "${LABEL_SELECTOR}" == "-h" ]]; then
    read -r -d '' USAGE <<'EOF'
NAME:
   cf_services_from_selector - List service instances from a selector expression

USAGE:
   cf_services_from_selector <selector expression> [ --summary ]
     see https://docs.cloudfoundry.org/adminguide/metadata.html#requirements-reference or extract below

EXAMPLES:
   cf_services_from_selector brokered_service_context_organization_guid==8ed390b9-8013-48d3-9669-2bddc308402a --summary
   cf_services_from_selector brokered_service_context_space_guid==b16cf265-0c97-4775-bd2a-29d9ffac20d1
   cf_services_from_selector brokered_service_originating_identity_user_id==5402eaf9-d7dd-4baf-83e5-12a741ad48aa

LABEL SELECTOR SYNTAX:
    Requirement | Format | Description
    -- | -- | --
    existence | KEY | Returns all resources labeled with the given key
    inexistence | !KEY | Returns all resources not labeled with the given key
    equality | KEY==VALUE or KEY=VALUE | Returns all resources labeled with the given key and value
    inequality | KEY!=VALUE | Returns all resources not labeled with the given key and value
    set inclusion | KEY in (VALUE1,VALUE2...) | Returns all resources labeled with the given key and one of the specified values
    set exclusion | KEY notin (VALUE1,VALUE2...) | Returns all resources not labeled with the given key and one of the specified values

EOF

    printf "${USAGE}\n"
    return 1
  fi

  #Save current target to restore it afterwards
  local current_target=$(cf t)
  local current_space=$(echo "$current_target" | awk '/space:/ {print $2}')
  local   current_org=$(echo "$current_target" | awk '/org:/ {print $2}')

  local METADATAS_JSON=$(cf curl "/v3/service_instances?label_selector=${LABEL_SELECTOR}")

  # {
  #   "errors": [
  #      {
  #         "detail": "The query parameter is invalid: Invalid label_selector value",
  #         "title": "CF-BadQueryParameter",
  #         "code": 10005
  #      }
  #   ]
  #}
  if [[ "$METADATAS_JSON" =~ "\"errors\"" ]]; then
    echo "$METADATAS_JSON"
    return 1
  fi
  #    "pagination": {
  #      "total_results": 0,
  #      "total_pages": 1,
  #      "first": {
  #         "href": "https://api.redacted-domain.org/v3/service_instances?label_selector=brokered_service_context_organization_guid%3D8ed390b9-8013-48d3-9669-2bddc3084&page=1&per_page=50"
  #      },
  #      "last": {
  #         "href": "https://api.redacted-domain.org/v3/service_instances?label_selector=brokered_service_context_organization_guid%3D8ed390b9-8013-48d3-9669-2bddc3084&page=1&per_page=50"
  #      },
  #      "next": null,
  #      "previous": null
  #   },
  #   "resources": []
  #}'
  if [[ $(echo "$METADATAS_JSON" | jq -r .pagination.total_results) -eq 0 ]]; then
    echo "No result matching selector"
#    echo "$METADATAS_JSON"
    return 1
  fi

  if [[ "$SUMMARY_OPTION" == "--summary" ]]; then
    local column_width="36"
    #See https://stackoverflow.com/a/12781750/1484823
    local formatting="| %-${column_width}s | %-${column_width}s | %-${column_width}s | %-${column_width}s | \n"
    printf "$formatting" "brokered_organization_name" "brokered_space_name" "brokered_instance_name" "backing_service_instance_guid"
    printf "$formatting" "--------------------------" "-------------------" "----------------------" "-----------------------------"
    # {
    #            "labels": {
    #               "brokered_service_instance_guid": "fe682093-d344-4251-862a-f31dee976012",
    #               "brokered_service_context_organization_guid": "8ed390b9-8013-48d3-9669-2bddc308402a",
    #               "brokered_service_originating_identity_user_id": "5402eaf9-d7dd-4baf-83e5-12a741ad48aa",
    #               "brokered_service_context_space_guid": "ad5e9858-fba9-4bc2-994b-3024557d5044",
    #               "backing_service_instance_guid": "cdbe1811-e1e9-45a7-b9b6-867ec7809b65"
    #            },
    #            "annotations": {
    #               "brokered_service_context_instance_name": "instance-name",
    #               "brokered_service_context_space_name": "space-name",
    #               "brokered_service_api_info_location": "api.cloudfoundry.redacted-domain.com/v2/info",
    #               "brokered_service_context_organization_name": "org-name"
    #            }
    # }
    # See https://stackoverflow.com/a/43192740/1484823
    echo "$METADATAS_JSON" | jq -r '.resources[].metadata | [ .annotations.brokered_service_context_organization_name, .annotations.brokered_service_context_space_name, .annotations.brokered_service_context_instance_name, .labels.backing_service_instance_guid ] | @tsv' |
      while IFS=$'\t' read -r brokered_organization_name brokered_space_name brokered_instance_name backing_service_instance_guid; do
        printf "$formatting" "$brokered_organization_name" "$brokered_space_name" "$brokered_instance_name" "$backing_service_instance_guid"
      done
    echo
    echo "Hint: try \"cf_service_instance_from_guid backing_service_instance_guid\" to display details, or remove --summary option to enter interactive mode"
    return 0
  fi

  local MATCHING_GUIDS=$(echo $METADATAS_JSON | jq -r '.resources[].metadata | .labels.backing_service_instance_guid')
  for si in $MATCHING_GUIDS; do
    echo "---------------------------------------------------------------------"
    echo " service instance guid=${si}"
    echo "---------------------------------------------------------------------"
    echo "metadata:"
    echo "$METADATAS_JSON" | jq -r ".resources[].metadata | select(.labels.backing_service_instance_guid==\"${si}\")"
    echo "---------------------------------------------------------------------"
    echo "service instance details:"
    cf_service_instance_from_guid "${si}" "--skip-reverse-lookup"
    echo "press Enter to proceed, to control-C to further inspect this service instance in the space"
    read user_input
  done
  if [[ -n "$current_org" && -n "$current_space" ]]; then
    #Restore initial target
    cf t -o $current_org -s $current_space >/dev/null
  fi
}
export -f cf_services_from_selector

#$1: guid
#$2: optional --skip-reverse-lookup
function cf_service_instance_from_guid() {
  local si=$1
  local skip_reverse_lookup_option=$2
  if [[ -z "${si}" || "${si}" == "-h" || -n $skip_reverse_lookup_option && $skip_reverse_lookup_option != "--skip-reverse-lookup" ]]; then
    read -r -d '' USAGE <<'EOF'
NAME:
   cf_service_instance_from_guid - Look up a given service instance from its guid

USAGE:
   cf_service_instance_from_guid backing-service-guid [ --skip-reverse-lookup ]

EXAMPLES:
   cf_service_instance_from_guid 7c8efe65-d18c-4ec3-bc79-0b4629cb6e9f
EOF

    printf "${USAGE}\n"
    return 1
  fi

  # validate guid is matching a service instance
  local service_instance_entity=$(cf curl v2/service_instances/$si)
  # '{
  #   "description": "The service instance could not be found: 7c8efe65-d18c-4ec3-bc79-0b4629cb6e9fXX",
  #   "error_code": "CF-ServiceInstanceNotFound",
  #   "code": 60004
  #}'
  if [[ $(echo "${service_instance_entity}" | jq -r .error_code) != "null" ]]; then
    echo "no service instance with guid= ${si}"
    return 1
  fi

  echo "$service_instance_entity" | jq -r '.entity | [ .name, .space_guid, .last_operation.state, .last_operation.created_at, .space_url, .service_plan_url ] | @tsv' |
    while IFS=$'\t' read -r service_instance_name space_guid state created_at space_url service_plan_url; do
      #echo "service_instance_name=${service_instance_name} space_guid=${space_guid} state=${state} created_at=${created_at} space_url=${space_url} service_plan_url=${service_plan_url}"
      cf curl ${space_url} | jq -r '.entity | [ .name, .organization_guid, .organization_url ] | @tsv' |
        while IFS=$'\t' read -r space_name organization_guid organization_url; do
          org_name=$(cf curl ${organization_url} | jq -r '.entity.name')
          #            echo "---------------------------------------------------------------------"
          #            echo "associated space:"
          #            echo "$ cf t -o $org_name -s $space_name"
          cf t -o $org_name -s $space_name >/dev/null
          if [[ -z "$skip_reverse_lookup_option" ]]; then
            echo "$ cf service $service_instance_name --guid"
            # as an optimization we fake this one
            #cf service $service_instance_name --guid
            echo "${si}"
          fi
          echo "$ cf service $service_instance_name"
          cf service $service_instance_name
        done
    done

}
export -f cf_service_instance_from_guid

# $1: optional --include-service-instances flag
function cf_org_space_hierarchy() {
  local OPTION=$1
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
    cf t -o $o >/dev/null
    local SPACES=$(cf spaces | tail -n +5)
    local org_dir="$top_dir/$o"
    mkdir -p $org_dir
    for s in $SPACES; do
      local space_dir="$org_dir/$s"
      if [[ $DISPLAY_SERVICE_INSTANCES != "true" ]]; then
        touch $space_dir # render as a file to get a different color
      else
        mkdir -p $space_dir
        cf t -o $o -s $s >/dev/null
        local SERVICES_INSTANCES=$(cf services | tail -n +4 | awk '{print $1}')
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

function cf_cmdb_cli_usage() {
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

  local cmdb_functions="cf_audit_events_from_guid cf_audit_events_from_service_name cf_usage_events_from_service_name cf_labels_service cf_service_details cf_service_instance_from_guid cf_services_from_selector cf_org_space_hierarchy"
  for f in $cmdb_functions; do
    $f -h | grep -A1 "NAME:" | grep -v "NAME:"
  done
}
export -f cf_cmdb_cli_usage
