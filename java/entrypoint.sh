#!/bin/sh

jq -s add docker.json $(find $VERTICLE_HOME/data -type f -exec readlink -f {} \; | grep '.*.json$') > $VERTICLE_SERVICE.json

java \
-Dio.netty.tryReflectionSetAccessible=true \
-Dio.netty.util.internal.ReflectionUtil=false \
-Dvertx.disableDnsResolver=true \
--add-modules java.se \
--add-exports java.base/jdk.internal.misc=ALL-UNNAMED \
--add-exports java.base/jdk.internal.ref=ALL-UNNAMED \
--add-opens java.base/java.lang=ALL-UNNAMED \
--add-opens java.base/java.nio=ALL-UNNAMED \
--add-opens java.base/sun.nio.ch=ALL-UNNAMED \
--add-opens java.management/sun.management=ALL-UNNAMED \
--add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED \
--illegal-access=warn \
-Dvertx.logger-delegate-factory-class-name=io.vertx.core.logging.SLF4JLogDelegateFactory \
-Dlog4j.configurationFile=log4j2.xml \
-Dhazelcast.diagnostics.enabled=true \
-Dhazelcast.logging.type=slf4j \
-jar $VERTICLE_SERVICE.jar \
-cp . \
-ha -cluster -conf $VERTICLE_SERVICE.json \
-DDEFAULT_JVM_OPTS="-Xms$VERTICLE_JAVA_XMS \
-Xmx$VERTICLE_JAVA_XMX -XX:MaxPermSize=$VERTICLE_JAVA_MAX_PERM_SIZE \
-XX:ReservedCodeCacheSize=$VERTICLE_JAVA_RESERVED_CODE_CACHE_SIZE"
