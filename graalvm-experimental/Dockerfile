FROM oracle/graalvm-ce:19.0.0

RUN gu install native-image

COPY graal.sh /tools/
COPY netty.json /tools/

WORKDIR /tools

ENTRYPOINT ["sh", "-c"]
CMD ["./graal.sh"]