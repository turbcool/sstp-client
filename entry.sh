#!/bin/bash
set -e

if [ -z "$REMOTEHOST" ]; then
    echo "ERROR: REMOTEHOST must be set"
    exit 1
fi
if [ -z "$SSTP_USER" ]; then
    echo "ERROR: SSTP_USER must be set"
    exit 1
fi
if [ -z "$SSTP_PASSWORD" ]; then
    echo "ERROR: SSTP_PASSWORD must be set"
    exit 1
fi

CERT_PATH="${CERT_FILE:-/certs/ca.crt}"
if [ -f "$CERT_PATH" ]; then
    echo "==> Installing custom CA certificate from $CERT_PATH"
    cp "$CERT_PATH" /usr/local/share/ca-certificates/custom-ca.crt
    update-ca-certificates 2>/dev/null
    echo "==> CA certificate installed"
fi

echo "==> Resolving SSTP server: $REMOTEHOST"
HOST_PART="${REMOTEHOST%%:*}"
SSTP_IP=$(getent hosts "$HOST_PART" | awk '{print $1}' | head -1)
if [ -n "$SSTP_IP" ]; then
    echo "==> SSTP server IP: $SSTP_IP"
else
    SSTP_IP="$HOST_PART"
    echo "==> Using SSTP server as-is: $SSTP_IP"
fi

echo "==> Starting SSTP connection to $REMOTEHOST"

SSTPC_CERT_ARGS=""
if [ -f "$CERT_PATH" ]; then
    echo "==> Using CA certificate: $CERT_PATH"
    SSTPC_CERT_ARGS="--ca-cert $CERT_PATH"
elif [ "${CERT_WARN}" = "1" ]; then
    echo "==> WARNING: Skipping certificate verification"
    SSTPC_CERT_ARGS="--cert-warn"
fi

exec sstpc \
    --user "$SSTP_USER" \
    --password "$SSTP_PASSWORD" \
    $SSTPC_CERT_ARGS \
    "$REMOTEHOST" \
    --log-stdout \
    --log-level 4 \
    --tls-ext \
    noauth \
    defaultroute
