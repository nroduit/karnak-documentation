---
title: Installation
weight: 5
description: Install and run the Karnak DICOM gateway with Docker Compose
---

Karnak is distributed as a container image on Docker Hub: [`nroduit/karnak`](https://hub.docker.com/r/nroduit/karnak) (multi-arch, `linux/amd64` and `linux/arm64`). It requires two third-party services:

* **PostgreSQL** for the persistence of the Karnak configuration (sources, destinations, projects, profiles, monitoring)
* **Redis** for the cache (pseudonym mappings, API call results)

The recommended way to run Karnak in production is **Docker Compose**. This page describes how to write the `docker-compose.yml` file and the associated configuration from scratch.

> [!INFO]
> Karnak is also available as a [portable distribution](../userguide/portable) that runs without Docker, with an embedded database and an in-memory cache. It is intended for a single machine and local use.

## Prerequisites

* Docker Engine 20.10 or later with the Compose plugin (`docker compose` v2). See the [Docker installation guide](https://docs.docker.com/engine/install/).
* The commands below target Linux. On Windows or macOS, use Docker Desktop and adapt the shell commands.

## 1. Create the project layout

Create a folder (for example `/opt/karnak`) with the following structure:

```text
karnak/
├── docker-compose.yml
├── karnak.env
└── secrets/
    ├── karnak_login_password
    ├── karnak_postgres_password
    └── karnak_db_encryption_key
```

## 2. Generate the secrets

Karnak reads sensitive values from files through the environment variables ending with `_FILE`, which is compatible with Docker secrets. Three secrets are required:

| Secret file | Purpose |
|-------------|---------|
| `karnak_login_password` | Password of the web portal administrator (login defined by `KARNAK_LOGIN_ADMIN`, `admin` by default) |
| `karnak_postgres_password` | Password of the PostgreSQL user, shared by the database container and Karnak |
| `karnak_db_encryption_key` | Key used by PostgreSQL (`pgcrypto`) to encrypt sensitive columns such as the client secrets of the API authentication configurations |

```bash
mkdir -p secrets
openssl rand -base64 32 | tr -d '=+/' > secrets/karnak_postgres_password
openssl rand -base64 48 | tr -d '=+/' > secrets/karnak_db_encryption_key
read -rsp "Web portal password: " pwd; echo; printf '%s' "$pwd" > secrets/karnak_login_password
chmod 600 secrets/*
```

> [!WARNING]
> Back up `karnak_db_encryption_key` together with the database. The key must stay identical for the whole life of the database: if it is lost or changed, the encrypted values stored in PostgreSQL can no longer be decrypted.

## 3. Write the docker-compose.yml file

```yaml
services:
  karnak:
    image: nroduit/karnak:v2.0.0
    container_name: karnak
    restart: unless-stopped
    ports:
      # DICOM listener: host port 11112 -> container port 11119 (DICOM_LISTENER_PORT)
      - "11112:11119"
      # Web portal (KARNAK_WEB_PORT, 8080 by default in the container)
      - "8080:8080"
    env_file: karnak.env
    environment:
      # Third-party services (container names on the Compose network)
      DB_HOST: karnak-db
      DB_PORT: "5432"
      DB_NAME: karnak
      DB_USER: karnak
      DB_PASSWORD_FILE: /run/secrets/karnak_postgres_password
      DB_ENCRYPTION_KEY_FILE: /run/secrets/karnak_db_encryption_key
      REDIS_HOST: karnak-cache
      REDIS_PORT: "6379"
      # Web portal administrator
      KARNAK_LOGIN_ADMIN: admin
      KARNAK_LOGIN_PASSWORD_FILE: /run/secrets/karnak_login_password
    secrets:
      - karnak_login_password
      - karnak_postgres_password
      - karnak_db_encryption_key
    depends_on:
      karnak-db:
        condition: service_healthy
      karnak-cache:
        condition: service_healthy
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
    networks:
      - karnak-net

  karnak-db:
    image: postgres:17-alpine
    container_name: karnak-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: karnak
      POSTGRES_USER: karnak
      POSTGRES_PASSWORD_FILE: /run/secrets/karnak_postgres_password
    volumes:
      - karnak-db-data:/var/lib/postgresql/data
    secrets:
      - karnak_postgres_password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U karnak -d karnak"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - karnak-net

  karnak-cache:
    image: redis:7-alpine
    container_name: karnak-cache
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - karnak-net

secrets:
  karnak_login_password:
    file: secrets/karnak_login_password
  karnak_postgres_password:
    file: secrets/karnak_postgres_password
  karnak_db_encryption_key:
    file: secrets/karnak_db_encryption_key

volumes:
  karnak-db-data:

networks:
  karnak-net:
```

Notes:

* Pin the Karnak image to a release tag (`v2.0.0`). The `latest` tag follows the most recent release and the `master` tag is the development build.
* Only the ports of the `karnak` service are published. The database and the cache are reachable from Karnak only, through the internal Compose network.
* `DB_PORT` is the port **inside** the Compose network (the default PostgreSQL port), not a port published on the host.
* Karnak does not need a writable volume: the configuration is stored in PostgreSQL and the logs are written to the standard output (see [Configuring Logs](logs)).

## 4. Write the karnak.env file

This file holds the gateway options. All variables are optional; the values below are the defaults. Uncomment and adapt what you need.

```bash
#  --------------------------------------------------------
#  DICOM listener
#  --------------------------------------------------------
DICOM_LISTENER_AET=KARNAK-GATEWAY
DICOM_LISTENER_PORT=11119
### Listen with DICOM TLS. When true, the TLS keystore and truststore below are required.
DICOM_LISTENER_TLS=false
#TLS_KEYSTORE_PATH=
#TLS_KEYSTORE_SECRET=
#TLS_TRUSTSTORE_PATH=
#TLS_TRUSTSTORE_SECRET=

#  --------------------------------------------------------
#  SMTP server (email notifications and conformance reports)
#  --------------------------------------------------------
#MAIL_SMTP_HOST=
#MAIL_SMTP_PORT=
#MAIL_SMTP_SENDER=
### Authentication type, "SSL" or "STARTTLS". Leave empty for an SMTP server without authentication.
#MAIL_SMTP_TYPE=
#MAIL_SMTP_USER=
#MAIL_SMTP_SECRET=

#  --------------------------------------------------------
#  Automatic pixel de-identification (external OCR service)
#  --------------------------------------------------------
#OCR_URL=http://localhost:8000

#  --------------------------------------------------------
#  Identity provider. IDP=oidc enables OpenID Connect, any other
#  value keeps the built-in administrator account.
#  --------------------------------------------------------
IDP=undefined
#OIDC_CLIENT_ID=
#OIDC_CLIENT_SECRET=
#OIDC_ISSUER_URI=

#  --------------------------------------------------------
#  Logging
#  --------------------------------------------------------
### Path of a custom Logback configuration file mounted in the container
#LOGBACK_CONFIGURATION_FILE=

### Additional JVM options, for example the heap size
#JAVA_OPTS=-Xmx4g
```

## 5. Start Karnak

Run the commands from the folder containing `docker-compose.yml`:

| Action | Command |
|--------|---------|
| Download or update the images | `docker compose pull` |
| Start in the background | `docker compose up -d` |
| Follow the logs | `docker compose logs -f` |
| Stop | `docker compose down` |
| Stop and delete the data (reset the database) | `docker compose down -v` |

On the first start, Karnak creates the database schema automatically. The database schema is also migrated automatically when you upgrade to a newer image.

Once started, with the configuration above:

* Web portal: <http://localhost:8080>, login `admin` with the password stored in `secrets/karnak_login_password`
* DICOM listener: AE Title `KARNAK-GATEWAY`, port `11112` on the Docker host

The next steps are described in the [user guide](../userguide): create a [forward node with its sources and destinations](../userguide/gateway), a [project](../userguide/projects) and a [de-identification profile](../profiles).

## Environment variables

### Web portal and database

| Variable | Default | Description |
|----------|---------|-------------|
| `KARNAK_WEB_PORT` | `8080` | Port of the web portal inside the container (the portable package uses `8081`) |
| `KARNAK_LOGIN_ADMIN` | `admin` | Login of the built-in administrator account |
| `KARNAK_LOGIN_PASSWORD` / `KARNAK_LOGIN_PASSWORD_FILE` | `undefined` | Password of the administrator account, as a value or as a file (Docker secret). |
| `DB_HOST` | `localhost` | Hostname of the PostgreSQL server |
| `DB_PORT` | `5432` | Port of the PostgreSQL server |
| `DB_NAME` / `DB_NAME_FILE` | `karnak` | Name of the database |
| `DB_USER` / `DB_USER_FILE` | `karnak` | Database user |
| `DB_PASSWORD` / `DB_PASSWORD_FILE` | `karnak` | Database password |
| `DB_ENCRYPTION_KEY` / `DB_ENCRYPTION_KEY_FILE` | `undefined` | Key used to encrypt sensitive columns in PostgreSQL. Required in production. |
| `REDIS_HOST` | `localhost` | Hostname of the Redis server |
| `REDIS_PORT` | `6379` | Port of the Redis server |
| `JAVA_OPTS` | | Additional options passed to the Java virtual machine |

A variable and its `_FILE` counterpart are exclusive: setting both makes the container exit with an error.

### DICOM listener

| Variable | Default | Description |
|----------|---------|-------------|
| `DICOM_LISTENER_AET` | `KARNAK-GATEWAY` | AE Title of the DICOM listener (calling AE Title used by Karnak toward the destinations) |
| `DICOM_LISTENER_PORT` | `11119` | Listening port inside the container |
| `DICOM_LISTENER_TLS` | `false` | Accept only DICOM TLS associations |
| `TLS_KEYSTORE_PATH` / `TLS_KEYSTORE_SECRET` | | Keystore and its password, required when TLS is enabled |
| `TLS_TRUSTSTORE_PATH` / `TLS_TRUSTSTORE_SECRET` | | Truststore and its password, required when TLS is enabled |

### Email

Email is used by the [destination notifications](../userguide/gateway/destinations/#4-notifications) and by the [conformance reports](../userguide/conformancereport).

| Variable | Description |
|----------|-------------|
| `MAIL_SMTP_HOST` | SMTP server hostname |
| `MAIL_SMTP_PORT` | SMTP server port |
| `MAIL_SMTP_SENDER` | Sender address of the emails |
| `MAIL_SMTP_TYPE` | `SSL` or `STARTTLS` to enable authentication. Leave empty for a server without authentication. |
| `MAIL_SMTP_USER` / `MAIL_SMTP_SECRET` | Credentials used when `MAIL_SMTP_TYPE` is set |

### Identity provider

By default, Karnak uses the built-in administrator account. Set `IDP=oidc` to delegate the authentication to an OpenID Connect provider such as Keycloak, and configure it with `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET` (or `OIDC_CLIENT_SECRET_FILE`) and `OIDC_ISSUER_URI`. See [Authentication](../userguide/authconfig) for details.

### Other services

| Variable | Default | Description |
|----------|---------|-------------|
| `OCR_URL` | `http://localhost:8000` | Base URL of the [de-identification image API](https://github.com/nroduit/image-ocr-identifier) used by the [automatic mask generation](../profiles/masks) and by the burned-in text check of the conformance report. Deploy this service separately (its repository provides a Docker Compose file) and point `OCR_URL` to it, for example `http://image-ocr-identifier:8000` when it runs on the same Docker network. |
| `LOGBACK_CONFIGURATION_FILE` | | Path of a custom Logback configuration, see [Configuring Logs](logs) |

## Run Karnak as a systemd service

To start Karnak automatically at boot, create a systemd unit that drives Docker Compose. The example below assumes the files are in `/opt/karnak`.

```ini
# /etc/systemd/system/karnak.service
[Unit]
Description=Karnak DICOM gateway (Docker Compose)
Requires=docker.service
After=docker.service network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/karnak
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

Then enable and start it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now karnak.service
sudo systemctl status karnak.service
```

## Reverse proxy

The web portal can be served behind a reverse proxy (HTTPS termination). Karnak honors the `X-Forwarded-*` headers, so make sure the proxy forwards them (`X-Forwarded-Proto`, `X-Forwarded-Host`, `X-Forwarded-For`) and that WebSocket connections are allowed, as the user interface relies on server push.

## Upgrade

1. Back up the database volume (`docker compose exec karnak-db pg_dump -U karnak karnak > karnak.sql`) and the `secrets/` folder.
2. Change the image tag in `docker-compose.yml` to the new release.
3. Run `docker compose pull` then `docker compose up -d`. The database schema is migrated automatically at startup.

## Build the image yourself

To build the image from the [source code](https://github.com/nroduit/karnak) instead of using Docker Hub, run from the root of the repository:

```bash
# Full build inside Docker (requires no local JDK)
docker build -t local/karnak:latest -f Dockerfile .

# Or build the application first, then package it
mvn clean install -P production
docker build -t local/karnak:latest -f src/main/docker/Dockerfile .
```

Then replace `image: nroduit/karnak:v2.0.0` by `image: local/karnak:latest` in `docker-compose.yml`.

## Other installation pages

{{% children description="true" %}}
