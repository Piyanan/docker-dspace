#!/bin/sh
### In postgresd.sh (make sure this file is chmod +x):
# `chpst -u postgres` runs the given command as the user `postgres`.
# If you omit that part, the command will be run as root.

exec chpst -u postgres /usr/lib/postgresql/9.4/bin/postgres -D /var/lib/postgresql/9.4/main -c config_file=/etc/postgresql/9.4/main/postgresql.conf  2>&1
