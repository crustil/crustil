#!/bin/sh

jq -s add docker.json $(find $VERTICLE_HOME/data -type f -exec readlink -f {} \; | grep '.*.json$') > $VERTICLE_SERVICE.json

java \
-Dio.netty.tryReflectionSetAccessible=true \
-Dvertx.disableDnsResolver=true \
--add-exports java.base/jdk.internal.misc=ALL-UNNAMED \
--illegal-access=warn \
-Dvertx.logger-delegate-factory-class-name=io.vertx.core.logging.SLF4JLogDelegateFactory \
-jar $VERTICLE_SERVICE.jar \
-cp . \
-ha -cluster -conf $VERTICLE_SERVICE.json \
-DDEFAULT_JVM_OPTS="-Xms$VERTICLE_JAVA_XMS \
-Xmx$VERTICLE_JAVA_XMX -XX:MaxPermSize=$VERTICLE_JAVA_MAX_PERM_SIZE \
-XX:ReservedCodeCacheSize=$VERTICLE_JAVA_RESERVED_CODE_CACHE_SIZE"
