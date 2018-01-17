#!/bin/sh

TIMESTAMP=$(date +%Y%m%d%H%M%S)
pg_dump --format=custom $QVAIN_DATABASE_NAME -f {{ qvain_db_backup_archive_path }}/qvain_db_{{ deployment_environment_id }}_backup_${TIMESTAMP}.dump
