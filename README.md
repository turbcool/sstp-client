# SSTP VPN Docker Client

Docker container that connects to an SSTP VPN server. Other containers can share its network namespace to route traffic through the VPN.

## Quick Start

```bash
cp .env.example .env
# Edit .env with your VPN credentials
mkdir -p certs
# (Optional) Place your server's CA certificate at certs/ca.crt
docker compose up -d
```

## Usage

Containers with `network_mode: "service:sstpc"` share the VPN tunnel:

```yaml
services:
  sstpc:
    build: ./sstp-client/.
    container_name: sstpc
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    privileged: true
    devices:
      - /dev/ppp:/dev/ppp
    environment:
      REMOTEHOST: ${REMOTEHOST}
      SSTP_USER: ${SSTP_USER}
      SSTP_PASSWORD: ${SSTP_PASSWORD}
    volumes:
      - ./sstp-client/certs:/certs:ro
    healthcheck:
      test: ["CMD-SHELL", "ip link show ppp0 2>/dev/null"]
      interval: 5s
      timeout: 3s
      retries: 30
      start_period: 10s

  app:
    image: nginx:alpine
    restart: unless-stopped
    network_mode: "service:sstpc"
    depends_on:
      sstpc:
        condition: service_healthy
```

## How routing works

The entrypoint script:

1. Resolves the SSTP server hostname to an IP
2. Pins a host route to the server via the original Docker gateway (prevents routing loop)
3. Connects via `sstpc` with `defaultroute` + `replacedefaultroute` + `noipdefault`
4. VPN becomes the default route; Docker subnet routes (more specific) take precedence for internal traffic

Result:
- **Docker-internal traffic** (same compose networks) → Docker subnet routes → direct
- **Internet traffic** → default route → `ppp0` → VPN

## Verify

```bash
# Check VPN tunnel is up
docker exec sstpc ip addr show ppp0

# Check public IP (should be VPN server's IP)
docker exec sstpc curl -s --max-time 5 ifconfig.me
```

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `REMOTEHOST` | Yes | | SSTP server address (e.g. `1.2.3.4:443`) |
| `SSTP_USER` | Yes | | VPN username |
| `SSTP_PASSWORD` | Yes | | VPN password |
| `CERT_FILE` | No | `/certs/ca.crt` | Path to CA certificate inside container |
| `CERT_WARN` | No | | Set to `1` to skip certificate verification |

## Self-Signed Certificates

**Option A** — Mount the CA cert (recommended):

```bash
echo | openssl s_client -connect 1.2.3.4:443 2>/dev/null | openssl x509 > certs/ca.crt
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
