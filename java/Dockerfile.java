FROM custom-java-vertx:latest

MAINTAINER Teddy Fontaine Sheol version: 1.0

ARG SERVICE=service

ENV VERTICLE_FILE="./target/$SERVICE.jar" \
    VERTICLE_HOME="/opt/verticles" \
    VERTICLE_SERVICE=$SERVICE \
    VERTICLE_JAVA_XMS="24m" \
    VERTICLE_JAVA_XMX="256m" \
    VERTICLE_JAVA_MAX_PERM_SIZE="48m" \
    VERTICLE_JAVA_RESERVED_CODE_CACHE_SIZE="48m" \
    VERTICLE_JAVA_MAX_RAM="320m"

RUN cp /usr/share/zoneinfo/Europe/Paris /etc/localtime \
    && echo "Europe/Paris" > /etc/timezone

RUN mkdir -p $VERTICLE_HOME/data

COPY $VERTICLE_FILE $VERTICLE_HOME/
COPY target/config/docker.json $VERTICLE_HOME/

WORKDIR $VERTICLE_HOME
ENTRYPOINT ["sh", "-c"]
CMD ["./entrypoint.sh"]
