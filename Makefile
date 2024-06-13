health:
	ansible-playbook health.yml -i inventories/wp.ini -f 20

.PHONY: python3
python3:
	ansible-playbook pb/install-python3.yml -i $(ip)

