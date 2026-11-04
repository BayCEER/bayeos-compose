# bayeos-compose

Runtime deployment configuration for the BayEOS V3 API stack using **Docker Hub images only**. Every service is pulled from Docker Hub.

## Usage

1. Copy the environment template and adjust as needed:

   ```sh
   cp .env_example .env
   ```

Set the required values in `.env`. Use strong, unique values and keep `.env` out of version control.

Image overrides are optional. To pin a release, uncomment and edit one or more
of `BAYEOS_API_IMAGE`, `BAYEOS_GATEWAY_IMAGE`, and `BAYEOS_POSTGRES_IMAGE` in
`.env`. Otherwise, Compose uses the defaults shown below.

2. Start the stack:

   ```sh
   docker compose up -d
   ```

   This pulls all images from Docker Hub and starts the full stack:

   | Service        | Image                                                      |
   | -------------- | ---------------------------------------------------------- |
   | questdb        | `questdb/questdb:latest`                                   |
   | jaeger         | `jaegertracing/jaeger:2.20.0`                              |
   | otel-collector | `otel/opentelemetry-collector-contrib:0.142.0`             |
   | postgresdb     | `${BAYEOS_POSTGRES_IMAGE:-bayceer/bayeos-postgres:latest}` |
   | bayeos-api     | `${BAYEOS_API_IMAGE:-bayceer/bayeos-api:latest}`           |
   | bayeos-gateway | `${BAYEOS_GATEWAY_IMAGE:-bayceer/bayeos-gateway:latest}`   |

   The postgres image is BayEOS-specific: it adds PL/Perl and Math::Spline for
   the gateway schema and creates the second gateway database on first initialization of the data volume.

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

Config-file changes (`jaeger-config.yaml`, `otel-collector-config.yaml`) take effect after recreating the container (`docker compose up -d jaeger` etc.). Changes to `.env` (e.g. a new `BAYEOS_API_IMAGE`, `POSTGRES_PASSWORD`, or `WS_API_KEY`) take effect the same way.

## HTTP and TLS

`bayeos-api` serves plain HTTP on port `5532`. It does not terminate TLS itself; to expose the API over HTTPS, place a reverse proxy (e.g. Apache HTTP Server in front and terminate TLS there. All services are bound to `127.0.0.1` (localhost only), so the reverse proxy runs natively on the same host and forwards to the loopback addresses listed below.

| Service        | Host address            |
| -------------- | ----------------------- |
| bayeos-api     | `127.0.0.1:5532`        |
| bayeos-gateway | `127.0.0.1:5533`        |
| jaeger         | `127.0.0.1:16686`       |
| questdb        | `127.0.0.1:9000`/`8812` |
| otel-collector | `127.0.0.1:4317`        |
| postgresdb     | `127.0.0.1:5432`        |

## Config files

- `jaeger-config.yaml`
- `otel-collector-config.yaml`

## Jaeger UI Reverse Proxy Config on Apache2

- set the base_path in file jaeger-config.yaml to run the Jaeger UI on base_path /jaeger
  ```yaml
  extensions:
    jaeger_query:
      base_path: /jaeger
  ```
- Recreate and restart the jaeger container
  ```sh
  docker compose up -d jaeger
  ```
- enable the apache modules
  ```sh
  a2enmod alias proxy proxy_http
  ```
- configure a new reverse proxy in /etc/apache2/conf-available

  ```sh
  LogLevel info
  Redirect permanent "/jaeger" "/jaeger/"
  ProxyPass "/jaeger/" "http://localhost:16686/jaeger/"
  ProxyPassReverse "/jaeger/" "http://localhost:16686/jaeger/"
  ```

  Alternative syntax with Location element:

  ```sh
  LogLevel info
  Redirect permanent "/jaeger" "/jaeger/"
  <Location "/jaeger/">
  ProxyPass "http://localhost:16686/jaeger/"
  ProxyPassReverse "http://localhost:16686/jaeger/"
  </Location>
  ```

- to restrict the proxied Jaeger UI to specific IPs, add a Require to the <Location> before ProxyPass
- enable the config with
  ```sh
  a2enconf <filename>
  ```
- reload apache with:
  ```sh
  systemctl reload apache2
  ```

## Data volumes

- `questdb_data`
- `postgresdb_data`
- `gateway_uploads`

Volumes can be removed with:

```sh
docker compose down -v
```

## PG Wire Access to questdb

Linux console client:

```bash
psql -h localhost -p 8812 -U admin -d qdb
```

Password: quest
