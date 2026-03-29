# Home-Ops 🏠

A highly secure, modular Docker Compose stack for self-hosting applications and websites. This project utilizes **Traefik** as a reverse proxy with automated Let's Encrypt SSL (via DNS challenges) and heavily emphasizes strict container security.

## 📂 Project Structure

- **`shared/`**: Contains global configurations and the DRY YAML `templates.yml` used to enforce project-wide security standards across all containers.
- **`core/`**: Infrastructure and backend services (grouped by domain, such as `database`, `routing`, and `system`). This includes Traefik (with a Docker Socket Proxy for security), MariaDB, Adminer, Gandi DDNS Updater, and Watchtower.
- **`apps/`**: End-user facing applications including ownCloud Infinite Scale (oCIS) with OnlyOffice, Roundcube Webmail, and a dedicated `websites/` grouping for Nginx-based static sites.
- **`docker-compose.yml`**: The master compose file that cleanly acts as the entrypoint and automatically includes all modular sub-services.
- **`security-hardening.sh`**: A utility script to lock down sensitive file permissions on the host machine.

## 🛡️ Security Highlights

This stack is built from the ground up with container security in mind:
- **Least Privilege:** Almost all containers drop all Linux capabilities (`cap_drop: ALL`) and only add back the strict minimum required to function.
- **Non-Root Execution:** Most services run as standard users (`PUID`/`PGID` 1000) using custom initialization containers to pre-configure volume permissions.
- **Read-Only Filesystems:** Core applications are forced to run with `read_only: true` by dynamically mounting strictly required `tmpfs` directories.
- **Socket Isolation:** Traefik does not have direct access to `docker.sock`. It reads through a heavily restricted, read-only TCP proxy proxying only container list requests.

## 🚀 Prerequisites

- Docker & Docker Compose (`docker compose` plugin)
- `apache2-utils` (or equivalent) to generate `htpasswd` hashes for the Traefik dashboard.
- A Gandi account and Personal Access Token (if using the default Let's Encrypt DNS challenge and DDNS setups).

## 🛠️ Quick Start

**1. Configure the Environment**

Copy the example environment file and fill in your specific details (domains, passwords, Gandi API tokens, and your user's `PUID`/`PGID`):

```bash
cp .env.example .env
nano .env
```

**2. Generate Traefik Dashboard Credentials**

Generate a secure password hash for the Traefik dashboard and paste it into `TRAEFIK_DASHBOARD_CREDENTIALS` inside your `.env` file (remember to escape `$` symbols as `$$` in the `.env` file!):

```bash
htpasswd -nB admin
```

**3. (Optional) Run Security Hardening**

Lock down the file permissions of your `.env` file to ensure that sensitive configuration files are secured "at rest":

```bash
chmod 600 .env
```

**4. Launch the Stack**

Initialize and start all services in the background. The setup utilizes init-containers, so permissions and initial database setups will be handled automatically on the first boot.

```bash
docker compose up -d
```

**5. Monitor Startup Logs**

Because heavy services like oCIS, OnlyOffice, and MariaDB need to initialize databases and extract web extensions on their very first run, it is recommended to monitor the logs:

```bash
docker compose logs -f
```