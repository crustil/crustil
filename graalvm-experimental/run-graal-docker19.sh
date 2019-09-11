#!/bin/sh

docker build -t graal19 -f Dockerfile19 .
docker run -it -v "$(readlink -f $(pwd))/../../api-gateway:/app" graal19