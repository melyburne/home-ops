# Home-Ops 🏠

A highly secure, modular Docker Compose stack for self-hosting applications and websites. This project utilizes **Traefik** as a reverse proxy with automated Let's Encrypt SSL (via DNS challenges) and heavily emphasizes strict container security.

## 📂 Project Structure

- **`core/`**: Infrastructure services (Traefik, MariaDB, DDNS Updater, Docker Socket Proxy).
- **`apps/`**: End-user applications (Roundcube Webmail, Adminer, Nginx Static Websites).
- **`docker-compose.yml`**: The master compose file that automatically includes all sub-services.
- **`security-hardening.sh`**: A utility script to lock down sensitive file permissions on the host machine.

## 🚀 Prerequisites

- Docker & Docker Compose
- `apache2-utils` (or equivalent) to generate `htpasswd` hashes for the Traefik dashboard.

## 🛠️ Quick Start

**1. Configure the Environment** Copy the example environment file and fill in your specific details (domains, passwords, Gandi API tokens, and your user's `PUID`/`GUID`):
```bash
cp .env.example .env
nano .env