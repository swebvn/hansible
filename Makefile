health:
	ansible-playbook health.yml -i inventories/wp.ini -f 20

.PHONY: python3
python3:
	ansible-playbook pb/install-python3.yml -i $(ip)

role:
	ansible-galaxy init roles/$(role)

lunar2-provision:
	ansible-playbook playbooks/lunar2-provision.yml -i ubuntu.local

setup-prod:
	cp ansible.cfg.prod ansible.cfg
	sed -i "s|\$WORKSPACE|$WORKSPACE|g" ansible.cfg

setup-prod-python3:
	cp ansible.cfg.prod.python3 ansible.cfg
	sed -i "s|\$WORKSPACE|$WORKSPACE|g" ansible.cfg