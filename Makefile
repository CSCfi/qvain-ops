all:

check:
	@cd tests && make check

venv:
	@python -m venv venv

update-test: venv
	@cd ansible && ./update-test.sh

update-stable: venv
	@cd ansible && ./update-stable.sh
