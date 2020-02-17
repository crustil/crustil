#!/usr/bin/env bash

set -e

if [[ ! -f config.properties ]]; then
    echo "config.properties not found!"
    exit -1
fi

typeset -A props
while IFS=$':= \t' read key value; do
  [[ ${key} = [#!]* ]] || [[ ${key} = "" ]] || props[$key]=${value}
done < config.properties

echo -e "======== Config properties ========"
echo -e "=> project_name: \t${props['project_name']}"
echo -e "=> domain: \t\t${props['domain']}"
echo -e "=> api: \t\t${props['api']}"
echo -e "=> registry: \t\t${props['registry']}"
echo -e "==================================="

export COMPOSE_PROJECT_NAME=${props['project_name']}

#nvm use stable

if [[ $(node --version) != "v12.4.0" ]]; then
    echo "Please use 'nvm use stable' (current stable node version: v12.4.0)"
    exit -1
fi

build() {
    cd $1
    ./build.sh $2
    cd -
}

if [[ $1 == "all" ]]; then
    build ../ sources
    build java
    build nginx
elif [[ $1 == "sources" ]]; then
    build ../ sources
elif [[ $1 == "java" ]]; then
    build java
elif [[ $1 == "nginx" ]]; then
    build nginx
elif [[ $1 == "docker" ]]; then
    build java
    build nginx
else
    echo -e "all\t build all sources and all docker images"
    echo -e "sources\t build only sources"
    echo -e "java\t build java docker images"
    echo -e "nginx\t build nginx docker images"
    echo -e "docker\t build all docker images"
    echo -e ""
    echo -e "$0 all|sources|java|nginx|docker"
fi