#!/bin/bash

# Run code Server
# Auth is handled by OAuth2 Proxy + authz-service, so disable built-in auth
/usr/bin/code-server --bind-addr 0.0.0.0:8443 --user-data-dir /config/data --extensions-dir /config/extensions --disable-telemetry --auth none /config/workspace

# Just for debug
# /usr/local/bin/looper.sh
