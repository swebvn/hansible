health:
	ansible-playbook health.yml -i inventories/wp.ini -f 20

.PHONY: python3
python3:
	ansible-playbook pb/install-python3.yml -i $(ip)

role:
	ansible-galaxy init roles/$(role)

lunar2:
	ansible-playbook playbooks/lunar2-provision.yml -i ubuntu.local

setup-prod:
	cp ansible.cfg.prod ansible.cfg