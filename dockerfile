FROM ubuntu:24.04

USER root

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /opt/devbox

SHELL [ "/bin/bash", "-c"]

COPY . /opt/devbox/

RUN chmod +x devbox.sh

RUN ./devbox.sh install