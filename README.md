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

| Service        | Image                                             |
| -------------- | ------------------------------------------------- |
| questdb        | `questdb/questdb:latest`                          |
| jaeger         | `jaegertracing/jaeger:2.20.0`                     |
| otel-collector | `otel/opentelemetry-collector-contrib:0.142.0`    |
| postgresdb     | `postgres:latest`                                 |
| bayeos-api     | `${BAYEOS_API_IMAGE:-oarchner/bayeos-api:latest}` |

The `bayeos-api` image is published on Docker Hub. Point it at a specific
release by setting `BAYEOS_API_IMAGE` in `.env` (see the `.env_example`
template).

## Environment

Copy `.env_example` to `.env` and set your values before first start. All
variables are optional — uncomment and set only what you need to override the
defaults in `docker-compose.yml`. Changes to `.env` take effect after
recreating the affected container (`docker compose up -d`).

## Updating

Pull the latest images and recreate changed containers:

```sh
docker compose pull
docker compose up -d
```

To update a single service (e.g. point `bayeos-api` at a new release by setting `BAYEOS_API_IMAGE` in `.env`):

```sh
docker compose pull bayeos-api
docker compose up -d bayeos-api
```

Config-file changes (`jaeger-config.yaml`, `otel-collector-config.yaml`) take
effect after recreating the container (`docker compose up -d jaeger` etc.).
Changes to `.env` (e.g. a new `BAYEOS_API_IMAGE`, `POSTGRES_PASSWORD`, or `WS_API_KEY`) take effect the same way.

## HTTP and TLS

`bayeos-api` serves plain HTTP on port `5532`. It does not terminate TLS itself; to expose the API over HTTPS, place a reverse proxy (e.g. Caddy or
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

## Config files

- `jaeger-config.yaml` and `otel-collector-config.yaml` are mounted read-only
  into the `jaeger` and `otel-collector` containers respectively.

## Data volumes

`questdb_data` and `postgresdb_data` are Docker named volumes. Please backup these files !

Volumes can be removed with:

```sh
docker compose down -v
```
