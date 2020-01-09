# cf-cli-cmdb-scripts

Scripts that complements CloudFoundry cli pending features, for use in osb-cmdb

## Prerequisites

* CF CLI
* JQ

## Getting started

```bash
$ source ./cf-cli-cmdb-functions.bash
$ cf_labels_service -h      
NAME:
   cf_labels_service - List all labels (key-value pairs) for a given service instance

USAGE:
   cf_labels_service SERVICE_INSTANCE_NAME

EXAMPLES:
   cf_labels_service my-mysql

$ cf_labels_service p-mysql-3aa96c94-1d01-4389-ab4f-260d99257215
{
    "labels": {
        "brokered_service_instance_guid": "3aa96c94-1d01-4389-ab4f-260d99257215",
        "brokered_service_context_organization_guid": "c2169b61-9360-4d67-968c-575f3a10edf5",
        "brokered_service_originating_identity_user_id": "0d02117b-aa21-43e2-b35e-8ad6f8223519",
        "brokered_service_context_space_guid": "1a603476-a3a1-4c32-8021-d2a7b9b7c6b4",
        "backing_service_instance_guid": "191260bb-3477-422d-8f40-bf053ccf6930"
    },
    "annotations": {
        "brokered_service_context_instance_name": "osb-cmdb-broker-0-smoketest-1578565892",
        "brokered_service_context_space_name": "smoke-tests",
        "brokered_service_api_info_location": "api.mycf.org/v2/info",
        "brokered_service_context_organization_name": "osb-cmdb-brokered-services-org-client-0"
    }
}

```
