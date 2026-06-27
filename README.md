# Home-Ops 🏠

A modular, secure Docker Compose stack for self-hosting applications and infrastructure. This project uses Traefik as a reverse proxy with automated SSL and focuses heavily on container security principles, including least privilege, non-root execution, and read-only filesystems.

## 📂 Project Structure

The stack is modular, splitting services into logical domains:

```text
.
├── apps/                  # End-user facing applications
│   ├── home-assistant/    # Smart Home automation (host network)
│   ├── ocis/              # ownCloud Infinite Scale & OnlyOffice
│   ├── roundcube/         # Webmail client
│   └── websites/          # Nginx-based static sites
├── core/                  # Infrastructure & backend services
│   ├── database/          # MariaDB & Adminer
│   ├── routing/           # Traefik Reverse Proxy & Gandi DDNS Updater
│   └── system/            # Watchtower (auto-updates) & Fallback error pages
├── shared/                # Global DRY configurations
│   └── templates.yml      # Base templates enforcing project-wide security standards
├── data-manager.sh        # System administration script for backups and restores
└── docker-compose.yml     # Master entrypoint importing all modular sub-services

```

## 🚀 Prerequisites

* Docker and Docker Compose plugin installed.
* `apache2-utils` (or equivalent) for generating `htpasswd` hashes.
* A configured domain and relevant API tokens (e.g., Gandi) if utilizing the default DNS challenge setup.
* UFW (Uncomplicated Firewall) enabled on the host machine.

## 🛠️ Quick Start

1. **Configure the Environment**

    Copy the example environment file and fill in your domains, passwords, and tokens.
    ```bash
    cp .env.example .env
    nano .env
    ```

2. **Generate Traefik Credentials**

    Generate a password hash for the Traefik dashboard. Replace `admin` with your preferred username.
    ```bash
    htpasswd -nB admin
    ```

    Copy the output and paste it into the `TRAEFIK_DASHBOARD_CREDENTIALS` variable in your `.env` file. Ensure you escape any `$` symbols by doubling them (e.g., `$$`).

3. **Secure Configuration Files**

    Restrict permissions on your environment file to protect sensitive data.
    ```bash
    chmod 600 .env
    ```

4. **Configure Firewall**

    To allow Traefik to securely communicate with Home Assistant without exposing port `8123` to the public internet, you must explicitly allow the Docker subnet in UFW:

    ```bash
    sudo ufw allow in from 172.16.0.0/12 to 172.17.0.1 port 8123 proto tcp comment 'Allow Traefik to Host Home Assistant'
    ```

    *Note: `172.16.0.0/12` is the standard private IP block Docker uses for bridge networks. `172.17.0.1` represents the default Docker gateway on the host.*

4. **Start the Stack**

    Initialize and run all services in the background. The setup uses init-containers to automatically handle directory permissions and initial database setups.
    ```bash
    docker compose up -d
    ```

## 💾 Backup and Restore

The repository includes a `data-manager.sh` script to handle cold backups. This script safely stops the containers, archives all dynamically found `data` directories (and the `.env` file) to ensure database consistency, and then restarts the stack.

**Note:** The script must be run as root to preserve correct file ownership and permissions.

### Preparation

Make the script executable (Run Once):

```bash
chmod +x data-manager.sh
```

### Create a Backup

To create a backup archive in a specified destination directory:

```bash
sudo ./data-manager.sh backup /path/to/backup/destination
```

### Restore from a Backup

To restore data from an existing .tar.gz archive (this will overwrite current data):

```bash
sudo ./data-manager.sh restore /path/to/backup/archive/home-ops-backup_YYYY-MM-DD_HH-MM-SS.tar.gz
```