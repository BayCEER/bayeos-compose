# bayeos-compose

Runtime deployment configuration for the BayEOS V3 API stack

## Usage

1. Copy the environment template and adjust as needed:

   ```sh
   cp .env_example .env
   ```

Set the required values in `.env`. Use strong, unique values and keep `.env` out of version control.

2. Start the stack:

   ```sh
   docker compose up -d
   ```

   This pulls images from Docker Hub and starts the full stack:

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

Some services serve plain HTTP. They doe not terminate TLS; to expose their API over HTTPS, place a reverse proxy (e.g. Apache HTTP Server in front and terminate TLS there. All services are bound to `127.0.0.1` (localhost only), so the reverse proxy runs natively on the same host and forwards to the loopback address.

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

Volumes are defined by pyth variables in .env.

To remove all volumes (Danger!) run:

```sh
docker compose down -v
```

## Logs
