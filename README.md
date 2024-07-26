# hansible

## Install wordpress plugin
This playbook also active the plugin after install it.

Copy the plugin zip file in `/roles/install-wp-plugin/files/` folder.

```bash
ansible-playbook playbooks/install-wp-plugin.yml -e "plugin_zip=example.zip  plugin_name=example"  -i inventory/hosts
```