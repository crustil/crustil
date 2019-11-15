#!/usr/bin/env bash

set -e

typeset -A config
typeset -A param

function setParam() {
	if [[ "$3" == "" ]]; then
		echo "= set ${1} to ${2}"
	fi
	[[ ${1} = [\#!]* ]] || [[ ${1} = "" ]] || param[$1]=${2}
}

function setConfig() {
	if [[ "$3" == "" ]]; then
		echo "= set ${1} to ${2}"
	fi
	[[ ${1} = [\#!]* ]] || [[ ${1} = "" ]] || config[$1]=${2}
  VAR=${1^^}
  export "CONFIG_${VAR//./_}=${2}"
}

# todo write usage
function usage() {
  echo "$0 start|stop|restart|scale|sh|dev|logs|status|purge|swarm[registry|pull|push|deploy|status|rm|leave]"
  # ./run.sh start law-service --project-path=../../micro-service/project --config-path=../config
  echo "todo"
}

# Default config
setParam "config.file.path" "./" 0
setParam "config.file.name" "config.properties" 0
setParam "project.path" "./" 0
setParam "compose.path" "./" 0

if [[ " $@ " =~ --config-path=([^' ']+) ]]; then
  setParam "config.file.path" ${BASH_REMATCH[1]}
fi

if [[ " $@ " =~ --config-name=([^' ']+) ]]; then
  setParam "config.file.name" ${BASH_REMATCH[1]}
fi

if [[ " $@ " =~ --project-path=([^' ']+) ]]; then
  setParam "project.path" ${BASH_REMATCH[1]}
fi

# --compose-path=[../,.,/home]
if [[ " $@ " =~ --compose-path=\[([^' ']+)\] ]]; then
  setParam "compose.path" ${BASH_REMATCH[1]}
fi

function generate_default_properties_file() {
  cat <<EOF > "${param['config.file.path']}/${param['config.file.name']}"
  project.name=framework
  project.version=0.0.1
  project.domain=<domain.fr>
  project.api=<api.domain.fr>

  registry=registry.cloudvector.fr/<project_name>
  addon.pos=41
  nginx.config.path=./nginx/

  db.connector=db
  db.root.host=%
  db.database=fc
  db.root.password=password
  db.user=test
  db.password=password
EOF
}

if [[ " $@ " == *" --generate-config-file "* ]]; then
  generate_default_properties_file
fi

if [[ ! -f ${param['config.file.path']}/${param['config.file.name']} ]]; then
    echo "error: ${param['config.file.path']}/${param['config.file.name']} not found!"
    exit -1
fi

while IFS=$':= \t' read key value; do
  if [[ "$key" != "" ]]; then
    setConfig ${key} ${value}
  fi
done < "${param['config.file.path']}/${param['config.file.name']}"

for service_key in "${!config[@]}"; do
	if [[ "$service_key" == *"project.services."* ]]; then
		if [[ "$INTERNAL_SERVICE_LIST" == "" ]]; then
   		INTERNAL_SERVICE_LIST="${config[$service_key]}"
		else
			INTERNAL_SERVICE_LIST="$INTERNAL_SERVICE_LIST,${config[$service_key]}"
 		fi
 	fi
done

if [[ " $@ " == *" --prod "* ]]; then
	echo "+ production mode, image from: ${config['registry']}/${config['project.name']}"
  export CONFIG_PROJECT_NAME=${config['registry']}/${config['project.name']}
fi

for current_compose_file in ${param['compose.path']//,/ }; do
  echo -e "\n# find compose files in: $current_compose_file"
  for current_compose_file in $(find $current_compose_file -type f -exec readlink -f {} \; | grep '.*-compose.yml'); do
    echo "-> found: $current_compose_file"
    if [[ "$COMPOSE_FILE" == "" ]]; then
      export COMPOSE_FILE="$current_compose_file"
    else
      export COMPOSE_FILE="$COMPOSE_FILE:$current_compose_file"
    fi
  done
done
echo ""

function service_list() {
    echo ==============================
    echo ========== Services ==========
    echo ==============================
    echo ${INTERNAL_SERVICE_LIST//,/$'\n'}
    echo ==============================
}

function cmd() {
    if [[ $2 == "all" ]]; then
      docker-compose $1 ${INTERNAL_SERVICE_LIST//,/ }
    elif [[ $2 == *"-service"* || $2 == *"-gateway"* ]]; then
			docker-compose $1 $2
		else
			project_service=${config['project.services.'$2]}
			if [[ "$project_service" != "" ]]; then
        docker-compose $1 ${project_service//,/ }
			else
				usage
			fi
    fi
}

function sql() {
    # $1 cmd sql dump & $2 file destination (sql)
    echo -e "## dump '${config['db.database']}' database => $1"
    docker exec -i ${config['project.name']}_${DB_CONNECTOR}_1 sh -c "exec mysqldump $1 -uroot -p${DB_ROOT_PASSWORD}" > ./sql/$2.sql
}

if [[ $1 == "stop" ]]; then
	if [[ $2 == "all" ]]; then
		docker-compose down
	else
    cmd "rm -svf" $2
	fi
elif [[ $1 == "purge" ]]; then
    if [[ $(docker-compose ps -q) != "" ]]; then
        docker rm -f $(docker-compose ps -q)
    fi
    if [[ $(docker images --filter=reference="*/${config['project.name']}/*" -q) != "" ]]; then
        docker rmi -f $(docker images --filter=reference="*/${config['project.name']}/*" -q)
    fi
    docker volume prune
elif [[ $1 == "start" ]]; then
    cmd "up -d" $2
    #if [[ $2 == "scale" ]]; then
    #    docker-compose up -d $(echo $(cat ./services-list-scale) | sed 's/ / --scale /g' | sed 's/^/--scale /') $(cat ./services-list-prod)
    #fi
elif [[ $1 == "build" ]]; then
    # todo move to external build script
    if [[ $2 == "java-service" ]]; then
      SERVICE_LIST_WITH_PATH=$(find ${param['project.path']} -type f | grep '.*-service\/pom.xml\|.*-gateway\/pom.xml' | egrep -o '.*\/([a-z-]+)-([a-z]+)')
      for item in $SERVICE_LIST_WITH_PATH; do
        if [[ "$item" =~ .*\/([a-z-]+-[a-z]+) ]]; then
          current_item=${BASH_REMATCH[1]}
          echo "build : $current_item"
          mkdir -vp "${param['project.path']}/${current_item}/target/config"
          echo "generate docker.json config"
          ( echo "cat <<EOF > ${param['project.path']}/${current_item}/target/config/docker.json" ; cat ${param['project.path']}/${current_item}/src/config/docker.json ) | sh
          docker build --build-arg SERVICE=${current_item} -t "${config['project.name']}/${current_item}" -f ./java/Dockerfile ${item}/
        fi
      done
    elif [[ $2 == "other" ]]; then
      echo "other build"
      docker-compose build $3
    fi
elif [[ $1 == "tool" ]]; then
    docker-compose up $2
elif [[ $1 == "restart" ]]; then
		cmd "down" $2
		cmd "up" $2
elif [[ $1 == "rm" ]]; then
			cmd "rm -svf" $2
elif [[ $1 == "rebuild" ]]; then
    cmd "down" all
		cmd "rm -svf" all
    java/build.sh
    start all
elif [[ $1 == "update" ]]; then
    if [[ $2 == "health-service" ]]; then
        CONTAINER_NAME="health-service"
        SERVICES=$(docker ps | awk '{print $NF}' | grep "${config['project.name']}_${CONTAINER_NAME}")
        FIRST_NUM=$(docker ps | awk '{print $NF}' | grep "${config['project.name']}_${CONTAINER_NAME}" | grep -c ${config['project.name']})
        echo ${CONTAINER_NAME}: ${SERVICES}
        echo ${CONTAINER_NAME}: ${FIRST_NUM}
        docker-compose up -d --no-recreate --scale "${CONTAINER_NAME}=$[${FIRST_NUM}*2]" "${CONTAINER_NAME}"
        # todo rewrite
        while read -r line; do
            echo ${line}
            docker stop ${line}
            docker rm ${line}
        done <<< ${SERVICES}
        docker-compose up -d --no-recreate --scale "${CONTAINER_NAME}=${FIRST_NUM}" "${CONTAINER_NAME}"
    elif [[ $2 == "list" ]]; then
        # todo rewrite
        while read -r CONTAINER_NAME; do
            SERVICES=$(docker ps | awk '{print $NF}' | grep "${config['project.name']}_${CONTAINER_NAME}")
            FIRST_NUM=$(docker ps | awk '{print $NF}' | grep "${config['project.name']}_${CONTAINER_NAME}" | grep -c ${config['project.name']})
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
        # todo rewrite
        docker-compose logs -ft --tail=100 ${DB_CONNECTOR} $(cat ./services-list-prod)
    else
        if [[ $2 != "" ]]; then
            tail="$2"
        else
            tail="all"
        fi
        docker-compose logs -ft --tail=${tail} $3
     fi
elif [[ $1 == "sh" ]]; then
    docker-compose exec $2 bash
elif [[ $1 == "scale" ]]; then
    service_list services-list-scale
    docker-compose up -d $(echo $(cat ./services-list-scale) | sed 's/ / --scale /g' | sed 's/^/--scale /') $(cat ./services-list-prod)
elif [[ $1 == "status" ]]; then
    service_list
    docker-compose ps --services
    docker-compose ps
elif [[ $1 == "swarm" && $# > 1 ]]; then
    if [[ $2 == "registry" ]]; then
        docker service create --network mynet --replicas 2 --name registry -p 5000:5000 registry:2
        docker service ls
    elif [[ $2 == "pull" ]]; then
        export CONFIG_PROJECT_NAME=${config['registry']}/${config['project.name']}
        if [[ $3 != "" ]]; then
            docker-compose pull
        else
            docker-compose pull
        fi
    elif [[ $2 == "push" && $3 != "all" ]]; then
        docker tag ${config['project.name']}/$3 ${config['registry']}/${config['project.name']}/$3:${VERSION}
        docker push ${config['registry']}/${config['project.name']}/$3:${VERSION}
        docker tag ${config['registry']}/${config['project.name']}/$3:${VERSION} ${config['registry']}/${config['project.name']}/$3:latest
        docker push ${config['registry']}/${config['project.name']}/$3:latest
    elif [[ $2 == "push" && $3 == "all" ]]; then
        while read -r line; do
            docker tag ${config['project.name']}/${line} ${config['registry']}/${config['project.name']}/${line}:${VERSION}
            docker push ${config['registry']}/${config['project.name']}/${line}:${VERSION}
            docker tag ${config['registry']}/${config['project.name']}/${line}:${VERSION} ${config['registry']}/${config['project.name']}/${line}:latest
            docker push ${config['registry']}/${config['project.name']}/${line}:latest
        done <<< $(echo $(cat ./services-list-prod) | tr " " "\n")
    elif [[ $2 == "bundle" ]]; then
        docker-compose bundle -o ${config['project.name']}-bundle.dab
    elif [[ $2 == "deploy" ]]; then
        docker-compose bundle -o deploy-swarm.dab
        docker stack deploy --bundle-file deploy-swarm.dab ${config['project.name']}
    elif [[ $2 == "status" ]]; then
        docker stack services ${config['project.name']}
    elif [[ $2 == "rm" ]]; then
        docker stack rm ${config['project.name']}
    elif [[ $2 == "leave" ]]; then
        docker swarm leave --force
    fi
elif [[ $1 == "database" ]]; then
    if [[ $2 == "dump" ]]; then
        echo -e "## dump '${config['db.database']}' database"
        sql "--databases ${config['db.database']}" save/${config['db.database']}-dump
        sql "--no-create-info --skip-triggers --no-create-db --databases ${config['db.database']}" save/${config['db.database']}-data-only-dump
    elif [[ $2 == "restore" ]]; then
        echo -e "Restore backup database"
        cat sql/save/${config['db.database']}-dump.sql | docker exec -i ${config['project.name']}_${DB_CONNECTOR}_1 sh -c "exec mysql ${config['db.database']} -uroot -p${DB_ROOT_PASSWORD}"
    elif [[ $2 == "init-script" ]]; then
        echo -e "## make init script for '${config['db.database']}'"
        echo -e "## make database base structure script"
        sql "--no-data --databases ${config['db.database']} --tables account token law group path" init/11-${config['db.database']}-init
        echo -e "## make law data script"
        sql "--extended-insert=FALSE --no-create-info --skip-triggers --no-create-db --databases ${config['db.database']} --tables law group path" init/12-${config['db.database']}-law-init
        echo -e "## make account data script"
        sql "--extended-insert=FALSE --no-create-info --skip-triggers --no-create-db --databases ${config['db.database']} --tables account" init/13-${config['db.database']}-account-init
    elif [[ $2 == "addons-script" ]]; then
        addon_nb=${config['addon.pos']}
        # todo rewrite
        while IFS= read -r addon; do
            IFS=';' read -r -a data <<< ${addon}
            name=${data[0]}
            tables=${data[@]:1}
            nb=$((addon_nb++))
            echo -e "## make addon ${data[0]} script"
            echo -e "${tables}"
            #--no-data
            sql "--no-create-db --databases ${config['db.database']} --tables ${tables}" init/${nb}-${config['db.database']}-addon-${name}-init
            echo "done"
        done <<< $(cat ./sql/addons)
    fi
else
    usage
fi
