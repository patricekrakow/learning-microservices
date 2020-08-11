#!/bin/bash
# chmod 755 client-x.sh

if [ -z "$API_HOST" ]; then
  API_HOST=localhost
fi
if [ -z "$API_PORT" ]; then
  API_PORT=3000
fi
while true
  do sleep 1
  echo "[INFO] $(\
    curl -s {$API_HOST}:{$API_PORT}/path-01 |\
      jq '.message + " | " + .internalInfo.serviceName + " (" + .internalInfo.version + ") | " + .internalInfo.hostname.fromOS' |\
        tr -d "\"")";
  echo "[INFO] $(\
    curl -s {$API_HOST}:{$API_PORT}/path-02 |\
      jq '.message + " | " + .internalInfo.serviceName + " (" + .internalInfo.version + ") | " + .internalInfo.hostname.fromOS' |\
        tr -d "\"")";
done
