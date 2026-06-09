FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sstp-client \
    ppp \
    ca-certificates \
    iproute2 \
    curl && \
    rm -rf /var/lib/apt/lists/*

COPY entry.sh /usr/bin/entry.sh
RUN chmod +x /usr/bin/entry.sh

ENTRYPOINT ["/usr/bin/entry.sh"]
