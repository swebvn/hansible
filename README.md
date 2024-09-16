# hansible

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
