#!/bin/bash

# Run code Server
/usr/bin/code-server --bind-addr 0.0.0.0:8443 --user-data-dir /config/data --extensions-dir /config/extensions --disable-telemetry --auth password /config/workspace

# Just for debug
/usr/local/bin/looper.sh
