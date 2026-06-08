# SSTP VPN Docker Client

Alpine-based Docker container that connects to an SSTP VPN server and shares the tunnel with other containers.

## Quick Start

```bash
cp .env.example .env
# Edit .env with your credentials
mkdir -p certs
# (Optional) Place your server's CA certificate at certs/ca.crt
docker compose up -d
```

Any container with `network_mode: "service:sstpc"` will route traffic through the VPN:

```yaml
services:
  sstpc:
    build: .
    container_name: sstpc
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    privileged: true
    devices:
      - /dev/ppp:/dev/ppp
    ports:
      - ${PORT:-8080}:${PORT:-8080}
    environment:
      REMOTEHOST: ${REMOTEHOST}
      SSTP_USER: ${SSTP_USER}
      SSTP_PASSWORD: ${SSTP_PASSWORD}
    volumes:
      - ./certs:/certs:ro

  app:
    image: nginx:alpine
    restart: unless-stopped
    network_mode: "service:sstpc"
```

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `REMOTEHOST` | Yes | | SSTP server address (e.g. `1.2.3.4:444`) |
| `SSTP_USER` | Yes | | VPN username |
| `SSTP_PASSWORD` | Yes | | VPN password |
| `PORT` | No | `8080` | Port to forward from containers |
| `CERT_FILE` | No | `/certs/ca.crt` | Path to CA certificate inside container |
| `CERT_WARN` | No | | Set to `1` to skip certificate verification |

## Self-Signed Certificates

**Option A** — Mount the CA cert (recommended):

```bash
# Extract cert from server
echo | openssl s_client -connect 1.2.3.4:444 2>/dev/null | openssl x509 > certs/ca.crt
```

**Option B** — Skip verification:

```yaml
environment:
  CERT_WARN: "1"
```

## Prerequisites

The host needs PPP kernel support:

```bash
sudo modprobe ppp_generic ppp_async ppp_mppe
[ -e /dev/ppp ] || sudo mknod /dev/ppp c 108 0
```

## License

MIT
