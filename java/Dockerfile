FROM openjdk:11.0-jre

MAINTAINER Teddy Fontaine Sheol version: 1.0

ARG SERVICE=service

ENV VERTICLE_FILE="target/$SERVICE.jar" \
    VERTICLE_HOME="/opt/verticles" \
    SERVICE=$SERVICE

RUN cp /usr/share/zoneinfo/Europe/Paris /etc/localtime \
    && echo "Europe/Paris" > /etc/timezone

COPY $VERTICLE_FILE $VERTICLE_HOME/
COPY target/config/docker.json $VERTICLE_HOME/
#COPY target/cluster.xml $VERTICLE_HOME/

WORKDIR $VERTICLE_HOME
ENTRYPOINT ["sh", "-c"]
CMD ["java -Dio.netty.tryReflectionSetAccessible=true -Dvertx.disableDnsResolver=true --add-exports java.base/jdk.internal.misc=ALL-UNNAMED --illegal-access=warn -Dvertx.logger-delegate-factory-class-name=io.vertx.core.logging.SLF4JLogDelegateFactory -jar $SERVICE.jar -cp . -ha -cluster -conf docker.json"]
