#!/bin/sh

native-image \
 --verbose \
 --no-server \
 --allow-incomplete-classpath \
 -Dio.netty.noUnsafe=true \
 --initialize-at-build-time=io.netty \
 --initialize-at-build-time=io.vertx \
 --initialize-at-build-time=ch.qos.logback \
 --initialize-at-build-time=org.slf4j \
 --initialize-at-build-time=com.fasterxml.jackson \
 --initialize-at-run-time=io.vertx.core.Launcher,io.netty.handler.codec.http.HttpObjectEncoder,io.netty.handler.codec.http.websocketx.WebSocket00FrameEncoder \
 -H:+ReportUnsupportedElementsAtRuntime \
 -H:+ReportExceptionStackTraces \
 -Dfile.encoding=UTF-8 \
 --no-fallback \
 -jar /app/target/api-gateway.jar

bash