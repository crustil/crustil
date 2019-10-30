#!/usr/bin/env bash

set -e

CONFIG_FILE_NAME="config.properties"
CONFIG_FILE_PATH="./"

if [[ " $@ " =~ --config-path=([^' ']+) ]]; then
  CONFIG_FILE_PATH=${BASH_REMATCH[1]}
  if [[ "$CONFIG_FILE_PATH" != "" ]]; then
    echo "= set config-path to $CONFIG_FILE_PATH"
  else
    echo "error: ${BASH_REMATCH[0]} is empty !"
    exit -1
  fi
fi

if [[ " $@ " =~ --config-name=([^' ']+) ]]; then
  CONFIG_FILE_NAME=${BASH_REMATCH[1]}
  if [[ "$CONFIG_FILE_PATH" != "" ]]; then
    echo "= set config-path to $CONFIG_FILE_NAME"
  else
    echo "error: ${BASH_REMATCH[0]} is empty !"
    exit -1
  fi
fi

generate_default_properties_file() {
  echo "project_name=<name>" > $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "domain=<domain.fr>" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "api=<api.domain.fr>" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "registry=registry.cloudvector.fr/<project_name>" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "version=0.0.1" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "db_connector=db" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "db_root_host=%" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "db_database=<database>" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "db_root_password=<password>" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "db_user=<username>" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "db_password=<password>" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
  echo "addon_pos=41" >> $CONFIG_FILE_PATH/$CONFIG_FILE_NAME
}

if [[ " $@ " == *" --generate-config-file "* ]]; then
  generate_default_properties_file
fi

if [[ ! -f $CONFIG_FILE_PATH/$CONFIG_FILE_NAME ]]; then
    echo "error: $CONFIG_FILE_PATH/$CONFIG_FILE_NAME not found!"
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
echo -e "=> version: \t\t${props['version']}"
echo -e "=> db-host: \t\t${props['db_root_host']}"
echo -e "=> db-database: \t${props['db_database']}"
echo -e "=> db-user: \t\t${props['db_user']}"
echo -e "=> addon-pos: \t\t${props['addon_pos']}"
echo -e "==================================="

export COMPOSE_FILE="services/init-compose.yml:services/elk-compose.yml:services/gateway-compose.yml:services/service-compose.yml:services/addons-service-compose.yml:services/database-compose.yml:dashboard/dashboard-compose.yml"

# todo add compose project list

export COMPOSE_PROJECT_NAME=${props['project_name']}

export DOMAIN=${props['domain']}
export API=${props['api']}
export REGISTRY=${props['registry']}
export VERSION=${props['version']}

export DB_CONNECTOR=${props['db_connector']}
export DB_ROOT_HOST=${props['db_root_host']}
export DB_DATABASE=${props['db_database']}
export DB_ROOT_PASSWORD=${props['db_root_password']}
export DB_USER=${props['db_user']}
export DB_PASSWORD=${props['db_password']}
export ADDON_POS=${props['addon_pos']}

function usage() {
    echo "$0 start|stop|restart|scale|sh|dev|logs|status|purge|swarm[registry|pull|push|deploy|status|rm|leave]"
}

function service_list() {
    echo ==============================
    echo ========== Services ==========
    echo ==============================
    echo $(cat ./$1) | tr " " "\n"
    echo ==============================
}

function start() {
    if [[ $1 == "all" ]]; then
        docker-compose up -d \
            traefik \
            hazelcast-management \
            elasticsearch \
            logstash \
            kibana \
            ${DB_CONNECTOR} \
            $(cat ./services-list-prod)
    elif [[ $1 == "stack" ]]; then
        docker-compose up -d ${DB_CONNECTOR} $(cat ./services-list-prod)
    elif [[ $1 == "prod" ]]; then
        docker-compose up -d \
            traefik \
            hazelcast-management \
            ${DB_CONNECTOR} \
            $(cat ./services-list-prod)
    elif [[ $1 != "" ]]; then
        docker-compose up -d $1 $2
    else
        usage
    fi
}

function stop() {
    if [[ $1 == "all" ]]; then
        docker-compose down
    elif [[ $1 == "stack" ]]; then
        docker-compose rm -svf $(cat ./services-list-prod)
    else
        docker-compose rm -svf $1
    fi
}

function sql() {
    # $1 cmd sql dump & $2 file destination (sql)
    echo -e "## dump '${DB_DATABASE}' database => $1"
    docker exec -i ${COMPOSE_PROJECT_NAME}_${DB_CONNECTOR}_1 sh -c "exec mysqldump $1 -uroot -p${DB_ROOT_PASSWORD}" > ./sql/$2.sql
}

if [[ $1 == "stop" ]]; then
    stop $2
elif [[ $1 == "purge" ]]; then
    if [[ $(docker-compose ps -q) != "" ]]; then
        docker rm -f $(docker-compose ps -q)
    fi
    if [[ $(docker images --filter=reference="*/${COMPOSE_PROJECT_NAME}/*" -q) != "" ]]; then
        docker rmi -f $(docker images --filter=reference="*/${COMPOSE_PROJECT_NAME}/*" -q)
    fi
    docker volume prune
elif [[ $1 == "start" ]]; then
    start $2
    if [[ $2 == "scale" ]]; then
        docker-compose up -d $(echo $(cat ./services-list-scale) | sed 's/ / --scale /g' | sed 's/^/--scale /') $(cat ./services-list-prod)
    fi
elif [[ $1 == "build" ]]; then
    docker-compose build $2
elif [[ $1 == "tool" ]]; then
      docker-compose up $2
elif [[ $1 == "restart" ]]; then
    stop $2
    start $2
elif [[ $1 == "rebuild" ]]; then
    stop all
    java/build.sh
    start all
elif [[ $1 == "update" ]]; then
    if [[ $2 == "health-service" ]]; then
        CONTAINER_NAME="health-service"
        SERVICES=$(docker ps | awk '{print $NF}' | grep "${COMPOSE_PROJECT_NAME}_${CONTAINER_NAME}")
        FIRST_NUM=$(docker ps | awk '{print $NF}' | grep "${COMPOSE_PROJECT_NAME}_${CONTAINER_NAME}" | grep -c ${COMPOSE_PROJECT_NAME})
        echo ${CONTAINER_NAME}: ${SERVICES}
        echo ${CONTAINER_NAME}: ${FIRST_NUM}
        docker-compose up -d --no-recreate --scale "${CONTAINER_NAME}=$[${FIRST_NUM}*2]" "${CONTAINER_NAME}"
        while read -r line; do
            echo ${line}
            docker stop ${line}
            docker rm ${line}
        done <<< ${SERVICES}
        docker-compose up -d --no-recreate --scale "${CONTAINER_NAME}=${FIRST_NUM}" "${CONTAINER_NAME}"
    elif [[ $2 == "list" ]]; then
        while read -r CONTAINER_NAME; do
            SERVICES=$(docker ps | awk '{print $NF}' | grep "${COMPOSE_PROJECT_NAME}_${CONTAINER_NAME}")
            FIRST_NUM=$(docker ps | awk '{print $NF}' | grep "${COMPOSE_PROJECT_NAME}_${CONTAINER_NAME}" | grep -c ${COMPOSE_PROJECT_NAME})
            echo ${CONTAINER_NAME}: ${SERVICES}
            echo ${CONTAINER_NAME}: ${FIRST_NUM}
            docker-compose up -d --no-recreate --scale "${CONTAINER_NAME}=$[${FIRST_NUM}*2]" "${CONTAINER_NAME}"
            echo "=====> wait new container has alive"
            sleep 90
            while read -r line; do
                echo ${line}
                if [[ ${line} != *"api-gateway"* && ${line} != *"health-service"* ]]; then
                    IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${line})
                    echo ${IP}
                    curl --header "Content-Type: application/json" \
                         --request POST \
                         --data '{"ip":"'${IP}'"}' \
                         http://health-service/api/trash
                    sleep 60
                fi
                docker stop ${line}
                docker rm ${line}
            done <<< ${SERVICES}
            docker-compose up -d --no-recreate --scale "${CONTAINER_NAME}=${FIRST_NUM}" "${CONTAINER_NAME}"
        done <<< $(cat ./services-list-update)
    fi
elif [[ $1 == "logs" ]]; then
    if [[ $2 == "stack" ]]; then
        docker-compose logs -ft --tail=100 ${DB_CONNECTOR} $(cat ./services-list-prod)
    else
        if [[ $2 != "" ]]; then
            tail="$2"
        else
            tail="all"
        fi
        docker-compose logs -ft --tail=${tail} $3
     fi
elif [[ $1 == "dev" ]]; then
    service_list services-list-dev
    docker-compose down
    docker-compose up -d \
            traefik \
            hazelcast-management \
            elasticsearch \
            logstash \
            kibana \
            ${DB_CONNECTOR} \
            $(cat ./services-list-dev)
        if [[ $2 != "" ]]; then
        tail="$2"
    else
        tail="all"
    fi
    docker-compose logs -ft --tail=${tail}
elif [[ $1 == "mysql-dev" ]]; then
    docker-compose up -d ${DB_CONNECTOR}
elif [[ $1 == "sh" && $# == 2 ]]; then
    docker-compose exec $2 bash
elif [[ $1 == "scale" ]]; then
    service_list services-list-scale
    docker-compose up -d $(echo $(cat ./services-list-scale) | sed 's/ / --scale /g' | sed 's/^/--scale /') $(cat ./services-list-prod)
elif [[ $1 == "status" ]]; then
    service_list services-list-prod
    docker-compose ps --services
    docker-compose ps
elif [[ $1 == "swarm" && $# > 1 ]]; then
    if [[ $2 == "registry" ]]; then
        docker service create --network mynet --replicas 2 --name registry -p 5000:5000 registry:2
        docker service ls
    elif [[ $2 == "pull" ]]; then
        if [[ $3 != "" ]]; then
            docker-compose pull $3
        else
            docker-compose pull
        fi
    elif [[ $2 == "push" && $# == 3 ]]; then
        docker tag ${COMPOSE_PROJECT_NAME}/$3 ${REGISTRY}/${COMPOSE_PROJECT_NAME}/$3:${VERSION}
        docker push ${REGISTRY}/${COMPOSE_PROJECT_NAME}/$3:${VERSION}
        docker tag ${REGISTRY}/${COMPOSE_PROJECT_NAME}/$3:${VERSION} ${REGISTRY}/${COMPOSE_PROJECT_NAME}/$3:latest
        docker push ${REGISTRY}/${COMPOSE_PROJECT_NAME}/$3:latest
    elif [[ $2 == "push" && $# == 2 ]]; then
        while read -r line; do
            docker tag ${COMPOSE_PROJECT_NAME}/${line} ${REGISTRY}/${COMPOSE_PROJECT_NAME}/${line}:${VERSION}
            docker push ${REGISTRY}/${COMPOSE_PROJECT_NAME}/${line}:${VERSION}
            docker tag ${REGISTRY}/${COMPOSE_PROJECT_NAME}/${line}:${VERSION} ${REGISTRY}/${COMPOSE_PROJECT_NAME}/${line}:latest
            docker push ${REGISTRY}/${COMPOSE_PROJECT_NAME}/${line}:latest
        done <<< $(echo $(cat ./services-list-prod) | tr " " "\n")
    elif [[ $2 == "deploy" ]]; then
        docker-compose bundle -o deploy-swarm.dab
        docker stack deploy --bundle-file deploy-swarm.dab ${COMPOSE_PROJECT_NAME}
    elif [[ $2 == "status" ]]; then
        docker stack services ${COMPOSE_PROJECT_NAME}
    elif [[ $2 == "rm" ]]; then
        docker stack rm ${COMPOSE_PROJECT_NAME}
    elif [[ $2 == "leave" ]]; then
        docker swarm leave --force
    fi
elif [[ $1 == "database" ]]; then
    if [[ $2 == "dump" ]]; then
        echo -e "## dump '${DB_DATABASE}' database"
        sql "--databases ${DB_DATABASE}" save/${DB_DATABASE}-dump
        sql "--no-create-info --skip-triggers --no-create-db --databases ${DB_DATABASE}" save/${DB_DATABASE}-data-only-dump
    elif [[ $2 == "restore" ]]; then
        echo -e "Restore backup database"
        cat sql/save/${DB_DATABASE}-dump.sql | docker exec -i ${COMPOSE_PROJECT_NAME}_${DB_CONNECTOR}_1 sh -c "exec mysql ${DB_DATABASE} -uroot -p${DB_ROOT_PASSWORD}"
    elif [[ $2 == "init-script" ]]; then
        echo -e "## make init script for '${DB_DATABASE}'"
        echo -e "## make database base structure script"
        sql "--no-data --databases ${DB_DATABASE} --tables account token law group path" init/11-${DB_DATABASE}-init
        echo -e "## make law data script"
        sql "--extended-insert=FALSE --no-create-info --skip-triggers --no-create-db --databases ${DB_DATABASE} --tables law group path" init/12-${DB_DATABASE}-law-init
        echo -e "## make account data script"
        sql "--extended-insert=FALSE --no-create-info --skip-triggers --no-create-db --databases ${DB_DATABASE} --tables account" init/13-${DB_DATABASE}-account-init
    elif [[ $2 == "addons-script" ]]; then
        addon_nb=${ADDON_POS}
        while IFS= read -r addon; do
            IFS=';' read -r -a data <<< ${addon}
            name=${data[0]}
            tables=${data[@]:1}
            nb=$((addon_nb++))
            echo -e "## make addon ${data[0]} script"
            echo -e "${tables}"
            #--no-data
            sql "--no-create-db --databases ${DB_DATABASE} --tables ${tables}" init/${nb}-${DB_DATABASE}-addon-${name}-init
            echo "done"
        done <<< $(cat ./sql/addons)
    fi
else
    usage
fi
