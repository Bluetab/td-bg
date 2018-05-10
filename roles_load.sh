#!/usr/bin/env bash

TDAUTH=http://localhost:4001/api
SESSIONS_ENDPOINT=$TDAUTH/sessions
TDBG=http://localhost:4002/api
ROLES_ENDPOINT=$TDBG/roles
PERMISSIONS_ENDPOINT=$TDBG/permissions

TOKEN=$(curl -s -X POST "$SESSIONS_ENDPOINT" -H "accept: application/json" -H "content-type: application/json" -d "{ \"user\": { \"user_name\": \"app-admin\", \"password\": \"mypass\" }}" | jq -r .token)
ALL_PERMISSIONS=$(curl -s -X GET "$PERMISSIONS_ENDPOINT" -H "accept: application/json" -H "Authorization: Bearer $TOKEN")

add_permissions() {
  role=$1
  permissions=$2
  role_id=$(curl -s -X POST "$ROLES_ENDPOINT" -H "accept: application/json" -H "Authorization: Bearer $TOKEN" -H "content-type: application/json" -d "{ \"role\": { \"name\": \"$role\" }}" | jq '.data.id')

  perms_input="[]"
  for name in ${permissions[*]}
  do
    id=$(echo $ALL_PERMISSIONS | jq --arg perm "$name" '.data[] | select(.name == $perm) | .id' )
    perms_input=$(echo $perms_input | jq -r --arg id "$id" --arg name "$name" '. += [{"id": $id, "name": $name}]')
  done

  curl -s -o /dev/null -X POST "$ROLES_ENDPOINT/$role_id/permissions" -H "accept: application/json" -H "Authorization: Bearer $TOKEN" -H "content-type: application/json" -d "{\"permissions\": $perms_input}"
}

ROLE_ADMIN="ROLE ADMIN"
ROLE_WATCH="ROLE WATCH"
ROLE_CREATE="ROLE CREATE"
ROLE_PUBLISH="ROLE PUBLISH"

ROLE_ADMIN_PERMSISSIONS=(create_acl_entry update_acl_entry delete_acl_entry create_domain update_domain delete_domain view_domain create_business_concept update_business_concept send_business_concept_for_approval delete_business_concept publish_business_concept reject_business_concept deprecate_business_concept manage_business_concept_alias view_draft_business_concepts view_approval_pending_business_concepts view_published_business_concepts view_versioned_business_concepts view_rejected_business_concepts view_deprecated_business_concepts)
ROLE_WATCH_PERMSISSIONS=(view_domain view_published_business_concepts view_versioned_business_concepts view_deprecated_business_concepts)
ROLE_CREATE_PERMSISSIONS=(view_domain create_business_concept update_business_concept send_business_concept_for_approval delete_business_concept view_published_business_concepts view_versioned_business_concepts view_deprecated_business_concepts)
ROLE_PUBLISH_PERMSISSIONS=(view_domain create_business_concept update_business_concept send_business_concept_for_approval delete_business_concept publish_business_concept reject_business_concept deprecate_business_concept manage_business_concept_alias view_draft_business_concepts view_approval_pending_business_concepts view_published_business_concepts view_versioned_business_concepts view_rejected_business_concepts view_deprecated_business_concepts)

add_permissions "$ROLE_ADMIN"   "${ROLE_ADMIN_PERMSISSIONS[*]}"
add_permissions "$ROLE_WATCH"   "${ROLE_WATCH_PERMSISSIONS[*]}"
add_permissions "$ROLE_CREATE"  "${ROLE_CREATE_PERMSISSIONS[*]}"
add_permissions "$ROLE_PUBLISH" "${ROLE_PUBLISH_PERMSISSIONS[*]}"
