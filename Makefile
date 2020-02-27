VENV:=source venv/bin/activate &&

all:

check:
	@cd tests && make check

venv:
	@python -m venv venv
	@$(VENV) pip install -r requirements.txt

update-test: venv
	@$(VENV) cd ansible && ./update-test.sh

update-stable: venv
	@$(VENV) cd ansible && ./update-stable.sh
