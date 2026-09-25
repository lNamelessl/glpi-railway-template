# GLPI on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/glpi-template)

One-click deploy of [GLPI](https://www.glpi-project.org) — the open-source IT helpdesk + asset management platform (tickets, CMDB inventory, SLAs, contracts, financial tracking) — with silent auto-install and MariaDB, zero manual configuration.

Deploy it from Railway's template marketplace, or fork this repo and deploy manually.

## What gets deployed

| Service | Image (pinned) | Manifest digest |
|---|---|---|
| GLPI | `glpi/glpi:11.0.9` | `sha256:7b50172cdb7d0878c57f4f0031837c40191dd8aced81d15598ed8f8880e0ba0e` |
| MariaDB | `mariadb:10.11` | `sha256:7f22313fc130a377a44999965bcb0a08dd5b21e8502824c1b864f792f9bc66ab` |

- **Silent auto-install**: all five `GLPI_DB_*` variables are wired before the first boot, so GLPI installs itself into MariaDB automatically — **no web install wizard**. (The official image only auto-installs when *all five* DB variables are set; if any is missing it falls back to the browser wizard.)
- **Persistent storage**: a single volume at `/var/glpi` holds everything that matters — DB config (`config_db.php`), uploaded files, logs, and marketplace plugins — and survives restarts and redeploys.
- **Background cron**: GLPI's built-in cron worker (`GLPI_CRONTAB_ENABLED=1`, the image default) runs notifications, SLA escalation, mail collectors, and inventory tasks inside the container.
- **Timezones pre-enabled**: the MariaDB service loads the timezone tables on first init and grants the `glpi` user access; the GLPI service enables them (`database:enable_timezones`) on every boot.
- **Private database**: MariaDB is reachable only over Railway's private network — nothing is exposed publicly.
- **First boot runs migrations**: expect the first deploy to take a few minutes; GLPI waits for MariaDB (up to 2 minutes) and retries on failure.

## First login (important — do this immediately)

1. Open your Railway domain and log in with **glpi / glpi**. This is the well-known super-admin account created by the installer — **change this password immediately** (top-right avatar → My Settings → Password, or Administration → Users → glpi → change password).
2. GLPI shows a **critical security banner** until the default accounts are fixed. After changing `glpi`, also change or disable the other seeded accounts under Administration → Users: `tech/tech`, `normal/normal`, and `post-only/postonly`.
3. Then create your first **ticket** (Assistance → Tickets → New ticket) or add your first **asset** (Assets → Computers → Add).

## Environment variables

The template needs **no deploy-form input**. Only three variables exist — all generated or referenced automatically:

| Variable | Service | Value |
|---|---|---|
| `MYSQL_PASSWORD` | mariadb | `${{secret(32)}}` — generated fresh per deployment, single source of truth |
| `GLPI_DB_HOST` | glpi | `${{mariadb.RAILWAY_PRIVATE_DOMAIN}}` |
| `GLPI_DB_PASSWORD` | glpi | `${{mariadb.MYSQL_PASSWORD}}` (reference — never duplicate the `secret()` call) |

Everything else uses the official images' built-in defaults: `GLPI_DB_NAME=glpi`, `GLPI_DB_USER=glpi`, `GLPI_DB_PORT=3306` (baked into the wrapper image), `MYSQL_DATABASE=glpi`, `MYSQL_USER=glpi`, and a random root password for MariaDB.

## Email notifications and LDAP

Outbound email (SMTP) and directory sync (LDAP) are configured inside GLPI after first login: **Setup → Notifications → Email notifications** for SMTP, **Setup → Authentication → LDAP directories** for LDAP. Neither is required to run the helpdesk.

## Backups

1. **Database**: dump MariaDB from the `mariadb` service (`railway ssh` → `mariadb-dump -uglpi -p glpi`, or point a scheduled dump tool at `mariadb.railway.internal:3306`).
2. **Files**: uploaded documents/plugins/logs live on the `glpi` service's volume at `/var/glpi` — snapshot it separately. Deleting the volume deletes uploads **and** the install marker (`config_db.php`), which would trigger a fresh install.

## Troubleshooting

- **First deploy looks slow**: first boot creates the full database schema. Give it several minutes; the service goes green when the healthcheck (`GET /healthz`, a static file served by Apache) starts passing.
- **Wizard appears instead of auto-install**: one of the five `GLPI_DB_*` variables is empty or was deleted. Restore them exactly as listed above (host/password must be *references*, not literal values).
- **Timezone warnings in GLPI**: the template pre-enables timezone support. If you see "timezone tables not loaded", check the `mariadb` deploy logs for the `Timezone tables loaded` line (it runs only on first init), then `railway ssh -s glpi` → `php bin/console database:enable_timezones`. The grant on `mysql.time_zone_name` is required — it is baked into the MariaDB init script.
- **Scheduled jobs (notifications, SLA) not firing**: the cron worker is enabled by default (`GLPI_CRONTAB_ENABLED=1`). Check `glpi` deploy logs for `[INFO] GLPI cron is enabled`; verify Setup → Automatic actions shows jobs running.
- **Version mismatch errors on install**: GLPI 11 requires **MariaDB ≥ 10.6 or MySQL ≥ 8.0**. This template pins `mariadb:10.11` — don't downgrade the image.
- **Uploaded files vanish after redeploying**: the `/var/glpi` volume was removed or the mount path changed.

## Cost

Two ~512 MB services + two small volumes ≈ **$5–10/month** on Railway's trial or Hobby plan. Raise the `glpi` service RAM if you add many agents, plugins, or asset inventory traffic.

## Wrapper changes vs the official image

The `glpi` service builds a thin wrapper on top of `glpi/glpi:11.0.9` (see `glpi/Dockerfile`):

1. **Volume ownership**: Railway mounts volumes as root; the official image runs as `www-data` and aborts when `/var/glpi` is not writable. The wrapper chowns the volume at boot, then drops to `www-data` (upstream entrypoint, cron worker, and Apache all run unprivileged as upstream intends).
2. **`/healthz`**: a static, dotless health route served by Apache without invoking PHP (Railway rejects healthcheck paths with dots).
3. **Timezone enable**: `php bin/console database:enable_timezones` runs after every install/update (idempotent).
4. **DB defaults baked in**: `GLPI_DB_NAME/USER/PORT` become image `ENV` literals so the marketplace deploy form stays empty (host + password stay as per-deploy expression variables).

The `mariadb` service builds on `mariadb:10.11` and adds one init script (`mariadb/01-timezones.sh`) that loads the timezone tables and grants the `glpi` user `SELECT` on `mysql.time_zone_name`.
