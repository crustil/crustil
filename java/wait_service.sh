#!/usr/bin/env bash

set -e

#COMPOSE_PROJECT_NAME=output
#service=db
#SERVICES=[api-gateway]

#if [[ " $@ " =~ --compose-path=\[([^' ']+)\] ]]; then
if [[ "${SERVICES}" =~ \[([^' ']+)\] ]]; then
  for service in ${BASH_REMATCH[1]//,/ }; do
    result=""
    while [ "${result}" != "\"healthy\"" ]; do
      result=$(curl -s --unix-socket /var/run/docker.sock http:/v1.4/containers/${COMPOSE_PROJECT_NAME}_${service}_1/json | jq '.State.Health.Status')
      echo "Wainting service ${service}...${result}..."
      sleep 1
    done
  done
fi
