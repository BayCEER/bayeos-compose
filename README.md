# bayeos-compose

Runtime deployment for the BayEOS V3 API stack using **Docker Hub images only**
(no local builds). Every service is pulled from Docker Hub.

## Usage

Copy the environment template and adjust as needed:

```sh
cp .env_example .env
```

Then start the stack:

```sh
docker compose up -d
```

This pulls all images from Docker Hub and starts the full stack:

| Service          | Image                                                  |
| ---------------- | ------------------------------------------------------ |
| questdb          | `questdb/questdb:latest`                               |
| jaeger           | `jaegertracing/jaeger:2.20.0`                          |
| otel-collector   | `otel/opentelemetry-collector-contrib:0.142.0`         |
| postgresdb       | `postgres:latest`                                      |
| bayeos-api       | `${BAYEOS_API_IMAGE:-oarchner/bayeos-api:latest}`     |

The `bayeos-api` image must be published on Docker Hub. Point it at a specific
release by setting `BAYEOS_API_IMAGE` in `.env` (see the `.env_example`
template).

## Environment

Copy `.env_example` to `.env` and set your values before first start. All
variables are optional — uncomment and set only what you need to override the
defaults in `docker-compose.yml`. Changes to `.env` take effect after
recreating the affected container (`docker compose up -d`).

Key variables:

- `BAYEOS_API_IMAGE` — which `bayeos-api` image to run
- `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` — PostgreSQL credentials
- `WS_API_KEY` — BayEOS API key
- `WS_API_PORT` — BayEOS API listen port (default `5532`)

## Updating

Pull the latest images and recreate changed containers:

```sh
docker compose pull
docker compose up -d
```

To update a single service (e.g. point `bayeos-api` at a new release by
setting `BAYEOS_API_IMAGE` in `.env`):

```sh
docker compose pull bayeos-api
docker compose up -d bayeos-api
```

Config-file changes (`jaeger-config.yaml`, `otel-collector-config.yaml`) take
effect after recreating the container (`docker compose up -d jaeger` etc.).
Changes to `.env` (e.g. a new `BAYEOS_API_IMAGE`, `POSTGRES_PASSWORD`, or
`WS_API_KEY`) take effect the same way.

## HTTP and TLS

`bayeos-api` serves plain HTTP on port `5532`. It does not terminate TLS
itself; to expose the API over HTTPS, place a reverse proxy (e.g. Caddy or
nginx) in front and terminate TLS there. All services are bound to
`127.0.0.1` (localhost only), so the reverse proxy runs natively on the same
host and forwards to the loopback addresses listed below.

| Service        | Host address                   |
| -------------- | ------------------------------ |
| bayeos-api     | `127.0.0.1:5532`               |
| jaeger         | `127.0.0.1:16686`              |
| questdb        | `127.0.0.1:9000`/`9009`/`8812` |
| otel-collector | `127.0.0.1:4317`               |
| postgresdb     | `127.0.0.1:5432`               |

## Publish Services using a Caddy reverse proxy

Caddy runs natively on the Debian host (not as a container) and terminates
TLS in front of `bayeos-api` and `jaeger`.

### Install Caddy

```sh
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

### Configure

Copy the example Caddyfile and set your domain:

```sh
sudo cp caddyfile_example /etc/caddy/Caddyfile
sudo nano /etc/caddy/Caddyfile   # replace your.domain.com
```

### Start / reload

```sh
sudo systemctl start caddy     # start now
sudo systemctl enable caddy    # start on boot
sudo systemctl reload caddy    # reload after editing the Caddyfile
```

### Public endpoints

- `https://your.domain.com/bayeos-api/*` → `bayeos-api`
- `https://your.domain.com/jaeger/*` → `jaeger`

### Update Caddy

```sh
sudo apt update
sudo apt upgrade caddy
```

## Config files

- `jaeger-config.yaml` and `otel-collector-config.yaml` are mounted read-only
  into the `jaeger` and `otel-collector` containers respectively.
- `caddyfile_example` is a reference Caddyfile for the host-level reverse
  proxy. Copy it to `/etc/caddy/Caddyfile` on the target Debian server.

## Data volumes

`questdb_data` and `postgresdb_data` are Docker named volumes. Remove them with:

```sh
docker compose down -v
```
