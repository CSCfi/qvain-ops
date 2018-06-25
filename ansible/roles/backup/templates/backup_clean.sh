#!/bin/sh

find {{ pg_backup_archive_path }} -type f -mtime +10 -delete
