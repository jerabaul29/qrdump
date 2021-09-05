FROM ubuntu:21.04

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN export LC_ALL="en_US.UTF-8"
RUN LANG="en_US.utf-8"
RUN LC_ALL="en_US.utf-8"
RUN LC_TIME="en_US.UTF-8"

RUN apt-get update && apt-get install -y apt-utils
RUN apt-get update && DEBIAN_FRONTEND=noninteractive && apt-get install -y tzdata

RUN apt-get update && apt-get install -y \
    qrencode \
    coreutils \
    zbar-tools \
    gzip \
    imagemagick \
    img2pdf \
    par2 \
    sudo \
    git \
    lsb-release \
 && rm -rf /var/lib/apt/lists/*

COPY . /

RUN sudo bash src/install.sh || echo "true"
RUN chmod +x /src/qrdump.sh

ENTRYPOINT ["/src/qrdump.sh"]
