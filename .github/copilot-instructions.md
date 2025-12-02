# Hansible - Copilot Instructions

## Project Overview
This is an Ansible automation repository for managing WordPress and Laravel (Lucommerce/Lunar) servers. It provisions servers, deploys applications, and manages infrastructure across multiple VPS providers (Contabo, DigitalOcean, Vultr, Veesp, etc.).

## Architecture
- **Playbooks** (`playbooks/`): Entry points for automation tasks
- **Roles** (`roles/`): Reusable task collections with files, templates, handlers
- **Inventories** (`inventories/*.ini`): Server groups organized by project (lunar, wordpress, offshore)

### Key Systems
| System | Purpose | Key Playbooks |
|--------|---------|---------------|
| **Lunar/Lucommerce** | Laravel multi-tenant SaaS | `lunar2-ci.yml`, `lunar2-provision.yml`, `lunar2-create-hub.yml` |
| **WordPress** | WordPress site management | `wordpress2-install.yml`, `install-wp-plugin.yml` |
| **Offshore** | Proxy/CDN servers | `offshore-provision.yml` |

## Zero-Downtime Deployment (Lunar)

### Directory Structure
Lunar uses symlink-based atomic releases for zero-downtime deployments:
```
/home/deploy/
├── current -> releases/20241202-143052/   # Symlink to active release
├── releases/                               # Release versions (keep 5)
│   ├── 20241202-143052/
│   └── 20241202-120015/
└── shared/                                 # Persistent data across releases
    ├── .env
    ├── storage/
    └── database/                           # SQLite tenant databases
```

### Deployment Flow
1. Clone fresh code to `/home/deploy/releases/<timestamp>/`
2. Symlink shared directories (`.env`, `storage/`, `database/`)
3. Run `composer install` + `pnpm build` (isolated, no downtime)
4. Run migrations **before** switch
5. Atomic symlink switch: `ln -sfn releases/<new> current`
6. Graceful PHP-FPM reload: `systemctl reload php8.2-fpm`
7. Cleanup old releases (keep 5)

### Key Commands
```bash
# Migrate existing server to symlink structure (one-time)
ansible-playbook playbooks/lunar2-migrate-to-symlink.yml -i inventories/lunar.ini --limit lunardev

# Deploy (uses zero-downtime automatically)
ansible-playbook playbooks/lunar2-ci.yml -i inventories/lunar.ini

# Instant rollback to previous release
ansible-playbook playbooks/lunar2-rollback.yml -i inventories/lunar.ini
```

### Critical Rules
- **Always use `systemctl reload`** not `restart` for PHP-FPM
- **Migrations must be backward-compatible** (run before symlink switch)
- **Shared directories** (`.env`, `storage/`, `database/`) persist across releases
- **Never modify files in `/home/deploy/current/`** directly

### Playbook Structure
- Use `become: true` with `become_method: sudo` for privilege escalation
- Reference roles by name (role directory = role name)
- Host exclusion pattern: `hosts: all:!lunardev` excludes `lunardev` group

### Role Structure
```
roles/<role-name>/
  tasks/main.yml      # Main task file (required)
  files/              # Static files (bash scripts)
  templates/          # Jinja2 templates (.j2)
  handlers/main.yml   # Service restart handlers
  vars/main.yml       # Role-specific variables
```

### Variable Naming
- Use `site_*` prefix for site-related vars: `site_domain`, `site_user`, `site_pass`, `site_root`
- Database vars: `db_name`, `db_user`, `db_password`
- Environment lookups: `"{{ lookup('env', 'BUNNY_API_KEY') }}"`

### Template Patterns
- Caddy configs: `templates/Caddyfile.j2` (use `root * /home/deploy/current/public`)
- Systemd services: `templates/horizon.service.j2` (use `/home/deploy/current/artisan`)
- PHP-FPM pools: `templates/php-fpm-pool.conf.j2`

## Tech Stack
- **Web Server**: Caddy (with PHP-FPM sockets at `/run/php/php8.x-fpm.sock`)
- **PHP**: 8.1 (WordPress), 8.2 (Lunar)
- **Database**: MySQL 8 (hub) + SQLite (tenants)
- **Queue**: Redis + Laravel Horizon
- **Node**: pnpm for package management
- **CDN**: BunnyCDN (storage zones, pull zones)

## Important Files
- `ansible.cfg`: Local development config
- `ansible.cfg.prod`: Production config (use `make setup-prod`)
- `roles/lunar2-ci/files/lunar-ci.sh`: Zero-downtime CI deployment script
- `roles/lunar2-create-hub/vars/main.yml`: BunnyCDN configuration
- `playbooks/lunar2-migrate-to-symlink.yml`: One-time migration to symlink structure

## Common Patterns

### Adding a new role
```bash
make role role=<role-name>  # Creates role scaffold via ansible-galaxy
```

### Deploying to specific hosts
The `lunardev` host is excluded from production CI playbooks. Use `lunar2-dev-ci.yml` for dev deployments.
Never run any ansible command directly because this is prohibited in this project. All servers in the project are production servers.
