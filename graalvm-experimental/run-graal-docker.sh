#!/bin/sh

docker build -t graal .
docker run -it -v "$(readlink -f $(pwd))/../../api-gateway:/app" graal
