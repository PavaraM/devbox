FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /opt/devbox

RUN sudo ./devbox.sh install

CMD ["/bin/bash"]

