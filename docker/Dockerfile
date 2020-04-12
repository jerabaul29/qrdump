FROM ubuntu:latest
MAINTAINER Jean Rabault (jean.rblt@gmail.com)

RUN apt-get update --fix-missing -y && \
    apt-get upgrade -y && \
    apt-get install apt-utils -y && \
    apt-get install git -y && \
    apt-get install qrencode -y && \
    apt-get install coreutils -y && \
    apt-get install zbar-tools -y && \
    apt-get install gzip -y && \
    apt-get install imagemagick -y && \
    apt-get install img2pdf -y && \
    apt-get install par2 -y && \
    apt-get autoremove -y

RUN mkdir Git

RUN cd Git && git clone https://github.com/jerabaul29/qrdump.git

CMD cd Git/qrdump/src && bash qrdump.sh --version
