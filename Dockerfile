FROM alpine:3.22

RUN apk add --no-cache \
    ppp \
    ca-certificates \
    bash \
    iproute2 \
    libevent \
    openssl \
    libstdc++ \
    libgcc \
    && apk add --no-cache --virtual .build-deps \
    build-base \
    libevent-dev \
    openssl-dev \
    ppp-dev \
    git \
    autoconf \
    automake \
    libtool \
    && cd /tmp \
    && git clone https://gitlab.com/eivnaes/sstp-client.git \
    && cd sstp-client \
    && ./autogen.sh \
    && ./configure --prefix=/usr --sysconfdir=/etc \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/sstp-client \
    && apk del .build-deps

RUN mkdir -p /usr/var/run/sstpc

COPY entry.sh /usr/bin/entry.sh
RUN chmod +x /usr/bin/entry.sh

ENTRYPOINT ["/usr/bin/entry.sh"]
