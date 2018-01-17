#!/bin/sh

find {{ qvain_db_backup_archive_path }} -type f -mtime +10 -delete
