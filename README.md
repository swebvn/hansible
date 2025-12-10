# hansible

## SSH Key Management
### Add SSH public key to deploy user
Add a public key to the `deploy` user's authorized_keys file. Keys are typically stored in the `keys/` folder.
```bash
ansible-playbook playbooks/add-ssh-key.yml -e "key_file=keys/q.pub" -i inventories/lunar.ini
```

### Remove SSH public key from deploy user
Remove a public key from the `deploy` user's authorized_keys file.
```bash
ansible-playbook playbooks/remove-ssh-key.yml -e "key_file=keys/q.pub" -i inventories/lunar.ini
```

## Install wordpress plugin
This playbook also active the plugin after install it.
Copy the plugin zip file in `/roles/install-wp-plugin/files/` folder.
Sample command
```bash
ansible-playbook playbooks/install-wp-plugin.yml -e "plugin_zip=intercept-carshield.zip  plugin_name=intercept-cardshield"  -i inventories/wordpress.ini
```

## Update wordpress plugin
Copy the plugin zip file in `/roles/update-wp-plugin/files/` folder.
Sample command
```bash
ansible-playbook playbooks/update-wp-plugin.yml -e "plugin_zip=intercept-cardshield.zip plugin_name=intercept-cardshield" -i inventories/wordpress.ini"
```

## Runn php artisan command (Lunar only)
Example
```bash
ansible-playbook playbooks/lunar-artisan.yml -e "command='php artisan inspire'" -i inventories/lunar.ini
```

## Migrate lunar server to v2
*Remember change the inventory file to new server*

Migrate lunar to v2 server
```bash
ansible-playbook playbooks/lunar2-migrate.yml -i lunar.ini
```

Setup the hub on new server, remember to point domain for each server, this can only run once.
```bash
export BUNNY_API_KEY=your_bunny_api_key
ansible-playbook playbooks/lunar2-createhub-hub.yml -i lunar.ini -e "domain=s322.tdalunar.com"
```


## Setup Ubuntu server and services for Wordpress sites
```bash
ansible-playbook -i inventories/wordpress2.ini playbooks/ubuntu-setup.yml --ask-become-pass
```

## Setup wordpress sites and install plugins
```bash
ansible-playbook -i inventories/wordpress2.ini playbooks/wordpress2-install.yml --ask-become-pass
```

## Server infor
```
user: username
password FTP: site_pass
user database: site_user
password user database: site_pass
DB name: site_user
```
