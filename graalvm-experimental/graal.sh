#!/bin/sh

native-image \
 -ea \
 --no-server \
 --verbose \
 -Dio.netty.noUnsafe=true  \
 -H:ReflectionConfigurationFiles=./netty.json \
 -H:+ReportUnsupportedElementsAtRuntime \
 -Dfile.encoding=UTF-8 \
 -Dio.netty.tryReflectionSetAccessible=true \
 -Dvertx.disableDnsResolver=true \
 --allow-incomplete-classpath \
 --language:llvm \
 --enable-all-security-services \
 --rerun-class-initialization-at-runtime=io.netty.handler.codec.http2.Http2CodecUtil \
 --delay-class-initialization-to-runtime=io.netty.handler.codec.http.HttpObjectEncoder,io.netty.handler.codec.http2.DefaultHttp2FrameWriter,io.netty.handler.codec.http.websocketx.WebSocket00FrameEncoder \
 -H:IncludeResources=META-INF/.* \
 -H:ReflectionConfigurationFiles=classes/${.}/reflection.json
 -jar /app/target/api-gateway.jar

bash