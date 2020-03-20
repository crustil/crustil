FROM custom-java-vertx:latest

MAINTAINER Teddy Fontaine Sheol version: 1.0

ARG SERVICE=service

ENV VERTICLE_FILE="./target/$SERVICE.jar" \
    VERTICLE_HOME="/opt/verticles" \
    VERTICLE_SERVICE=$SERVICE \
    VERTICLE_JAVA_XMS="400m" \
    VERTICLE_JAVA_XMX="1024m" \
    VERTICLE_JAVA_MAX_PERM_SIZE="128m" \
    VERTICLE_JAVA_RESERVED_CODE_CACHE_SIZE="48m"

RUN cp /usr/share/zoneinfo/Europe/Paris /etc/localtime \
    && echo "Europe/Paris" > /etc/timezone

RUN mkdir -p $VERTICLE_HOME/data

COPY $VERTICLE_FILE $VERTICLE_HOME/
COPY target/config/docker.json $VERTICLE_HOME/

#COPY target/cluster.xml $VERTICLE_HOME/

WORKDIR $VERTICLE_HOME
ENTRYPOINT ["sh", "-c"]
CMD ["./entrypoint.sh"]
