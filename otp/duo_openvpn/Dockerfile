# Original credit: https://github.com/jpetazzo/dockvpn

# Smallest base image
FROM alpine:3.4

MAINTAINER El-ad Blech <elie@theinfamousblix.com>

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn iptables bash easy-rsa alpine-sdk python && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    mkdir -p /opt/duo/src && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

VOLUME ["/opt/duo"]

ENV DUOGIT "https://github.com/duosecurity/duo_openvpn/archive/master.zip"

CMD ["makeduo"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*
