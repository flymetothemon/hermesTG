# Hermes Agent on Railway

This template runs the **official Hermes Agent Docker image** on Railway. The template adds only the Railway-specific port bridge and deployment configuration; Hermes' runtime, gateway supervision, dashboard authentication, dependency set, and database stack stay upstream-managed.

## What is included

- Official Hermes Agent image with the current container architecture
- s6-overlay supervision for the gateway and dashboard
- Python 3.13 and Node 26 from the upstream image
- fixed SQLite build with the WAL-reset corruption fix
- non-root Hermes runtime and immutable `/opt/hermes`
- persistent state under `/opt/data`
- native Hermes dashboard authentication
- Railway-aware dynamic port handling and `/api/health` readiness checks

The upstream image is the source of truth. Rebuilding this template pulls the current `nousresearch/hermes-agent:latest` image instead of cloning or mutating a Git checkout at startup.

## Deploy

### 1. Create the service

Deploy the template from Railway and generate a public domain for the service.

### 2. Configure dashboard authentication

Set:

- `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` — usually `admin`
- `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` — a strong secret

Do not use the old `DASHBOARD_USER` / `DASHBOARD_PASSWORD` variables; those belonged to the removed custom auth proxy.

Railway templates support generated secrets, so a template publisher can provision `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` with a template `secret(...)` variable rather than storing a password in source.

### 3. Attach persistent storage

Attach a Railway Volume at:

```text
/opt/data
```

This directory is Hermes' persistent state root and contains configuration, credentials, sessions, memories, skills, cron data, logs, profiles, and related runtime state.

### 4. Configure Hermes

Open the Railway public URL and sign in. Configure the model provider and messaging integrations from the Hermes dashboard, or provide their environment variables through Railway when appropriate.

For Telegram, for example, provide the required bot token and configure allowed users according to Hermes' current gateway documentation.

## Ports and health checks

Railway provides the `PORT` environment variable. `railway-entrypoint.sh` maps that value to `HERMES_DASHBOARD_PORT` before starting Hermes' upstream s6-overlay init process, so the dashboard listens on the same port Railway probes.

Railway health checks use:

```text
GET /api/health
```

Hermes intentionally exposes `/api/health` as a public, read-only liveness endpoint so external uptime/health systems can probe an authenticated dashboard safely.

## Updating Hermes

There is no runtime `git pull` and no `uv pip install` during container startup.

The template uses:

```text
nousresearch/hermes-agent:latest
```

When the service is rebuilt, Railway pulls the current upstream image. Persistent Hermes state remains under `/opt/data`, so image replacement does not replace configuration or session data.

For a controlled release cadence, use a specific upstream Hermes image tag instead of `latest` by changing the `FROM` line in the Dockerfile, for example:

```dockerfile
FROM nousresearch/hermes-agent:v2026.8.27
```

## SQLite / WAL-reset protection

Hermes' current official Docker image builds and verifies a newer SQLite instead of relying on Debian's SQLite 3.46.1 package. The Railway wrapper also performs a build-time check and fails the image build if SQLite is below 3.51.3.

This prevents deploying the known SQLite WAL-reset corruption issue that motivated the original template update.

## Resource guidance

Hermes' browser automation is the most memory-intensive feature. Railway deployments using Chromium/Playwright should have materially more memory than a messaging-only deployment; the upstream Hermes Docker documentation recommends roughly 2–4 GB for browser-heavy workloads.

## Removed legacy components

The following template-specific components were intentionally removed:

- `auth_proxy.py`
- `entrypoint.sh`
- runtime Git auto-update
- custom gateway process management
- custom gateway status/restart API injection
- duplicate `railway.toml`
- `/root/.hermes` as the persistent data path

These responsibilities now belong to the official Hermes image and its native dashboard/gateway architecture.

## References

- Hermes Agent Docker documentation: https://hermes-agent.nousresearch.com/docs/user-guide/docker/
- Hermes Agent repository: https://github.com/NousResearch/hermes-agent
- Railway health checks: https://docs.railway.com/deployments/healthchecks
- Railway template variable functions: https://docs.railway.com/templates/create
