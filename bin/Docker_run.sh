#!/usr/bin/env bash

# remove stale pid files
rm -f "$APP_HOME/tmp/pids/server.pid" > /dev/null 2>&1

# run migrations if necessary
rake db:migrate

rails server -b 0.0.0.0 -p 3000
