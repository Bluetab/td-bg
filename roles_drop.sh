#!/usr/bin/env bash

TDAUTH=http://localhost:4001/api
SESSIONS_ENDPOINT=$TDAUTH/sessions
TDBG=http://localhost:4002/api
ROLES_ENDPOINT=$TDBG/roles

TOKEN=$(curl -s -X POST "$SESSIONS_ENDPOINT" -H "accept: application/json" -H "content-type: application/json" -d "{ \"user\": { \"user_name\": \"app-admin\", \"password\": \"mypass\" }}" | jq -r .token)
ROLES=$(curl -s -X GET "$ROLES_ENDPOINT" -H "accept: application/json" -H "Authorization: Bearer $TOKEN" | jq -r '.data | .[] | .id')
for r in $ROLES
do
  curl -s -o /dev/null -X POST "$ROLES_ENDPOINT/$r/permissions" -H "accept: application/json" -H "Authorization: Bearer $TOKEN" -H "content-type: application/json" -d "{ \"permissions\": [ ]}"
  curl -s -o /dev/null -X DELETE "$ROLES_ENDPOINT/$r" -H "accept: application/json" -H "Authorization: Bearer $TOKEN" -H "content-type: application/json"
done
