#!/usr/bin/env bash

set -e

while read -r line; do
    echo ${line}
    if [[ ! -d ./../../${line}/tmp ]]; then
        echo "create tmp folder"
        mkdir ./../../${line}/tmp
    fi
    echo "copy tmp files"
    cp ./../../docker/nginx/nginx.conf ./../../${line}/tmp/
    cp ./../../docker/nginx/config.json ./../../${line}/dist/${line}/assets/
    cp ./../../docker/nginx/nginx.vh.default.conf ./../../${line}/tmp/
    cp ./../../docker/nginx/startup.sh ./../../${line}/tmp/
    cp ./../../health-agent/target/x86_64-unknown-linux-musl/release/health-agent ./../../${line}/tmp/
    echo "make docker image"
    docker build --build-arg DASHBOARD=${line} -t "${COMPOSE_PROJECT_NAME}/${line}" -f ./Dockerfile ./../../${line}/
    echo "remove tmp files"
    rm -r ./../../${line}/tmp/*
done <<< $(echo $(cat ./dashboard-list) | tr " " "\n")