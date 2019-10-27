FROM debian:jessie

RUN apt-get update && apt-get install wget lsb-release apt-transport-https ca-certificates -y

RUN echo "deb https://download.rethinkdb.com/apt `lsb_release -cs` main" | tee /etc/apt/sources.list.d/rethinkdb.list
RUN wget -qO- https://download.rethinkdb.com/apt/pubkey.gpg | apt-key add -
RUN apt-get update && apt-get install rethinkdb python3 python3-pip -y

RUN mkdir /data

RUN pip3 install rethinkdb
RUN pip3 install --upgrade setuptools pip
