ansible-playbook -i inventories/$1 -e @/home/jn/private/secrets-$1.yaml install_app.yml
