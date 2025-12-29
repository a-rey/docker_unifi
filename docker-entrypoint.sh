#!/bin/bash

echo "[`date`][docker-entrypoint.sh] starting ..."
echo "[`date`][docker-entrypoint.sh] user: $(id)"
/usr/lib/unifi/bin/unifi.init start
if [ $? -ne 0 ]; then
  echo "[`date`][docker-entrypoint.sh] server startup error: $?"
  exit 1
fi
echo "[`date`][docker-entrypoint.sh] server startup OK"
tail -f /dev/null
