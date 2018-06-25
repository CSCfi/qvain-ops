#!/bin/sh

TIMESTAMP=$(date +%Y%m%d%H%M%S)
pg_dump --format=custom {{ database.name }} -f {{ pg_backup_archive_path }}/{{ app.name }}_db_{{ deployment_environment_id }}_backup_${TIMESTAMP}.dump
