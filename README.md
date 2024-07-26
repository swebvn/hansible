# hansible

## Install wordpress plugin
This playbook also active the plugin after install it.
Copy the plugin zip file in `/roles/install-wp-plugin/files/` folder.
```bash
ansible-playbook playbooks/install-wp-plugin.yml -e "plugin_zip=intercept-carshield.zip  plugin_name=intercept-cardshield"  -i inventory/wordpress.ini
```