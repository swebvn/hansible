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
- Caddy configs: `templates/Caddyfile.j2`, `templates/caddy-site.conf.j2`
- Systemd services: `templates/horizon.service.j2`
- PHP-FPM pools: `templates/php-fpm-pool.conf.j2`

## Tech Stack
- **Web Server**: Caddy (with PHP-FPM sockets at `/run/php/php8.x-fpm.sock`)
- **PHP**: 8.1 (WordPress), 8.2 (Lunar)
- **Database**: MySQL 8
- **Queue**: Redis + Laravel Horizon
- **Node**: pnpm for package management
- **CDN**: BunnyCDN (storage zones, pull zones)

## Important Files
- `ansible.cfg`: Local development config
- `ansible.cfg.prod`: Production config (use `make setup-prod`)
- `roles/lunar2-ci/files/lunar-ci.sh`: CI deployment script with git-based conditional builds
- `roles/lunar2-create-hub/vars/main.yml`: BunnyCDN configuration

## Common Patterns

### Adding a new role
```bash
make role role=<role-name>  # Creates role scaffold via ansible-galaxy
```

### Deploying to specific hosts
The `lunardev` host is excluded from production CI playbooks. Use `lunar2-dev-ci.yml` for dev deployments.
Never run any ansible command directly because this is prohibited in this project. All server in the project is production server.
