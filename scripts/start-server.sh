#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -f .env ]]; then
  while IFS='=' read -r name value || [[ -n "${name:-}" ]]; do
    name="${name%$'\r'}"
    [[ "$name" =~ ^[A-Za-z_][A-Za-z_0-9]*$ ]] || continue
    value="${value%$'\r'}"
    if [[ "$value" == \"*\" || "$value" == \'*\' ]]; then value="${value:1:${#value}-2}"; fi
    export "$name=$value"
  done < .env
fi
if [[ -z "${NSO_MYSQL_PASSWORD:-}" ]]; then
  echo "Set NSO_MYSQL_PASSWORD in a private .env file before starting the server." >&2
  exit 1
fi
exec java -Dfile.encoding=UTF-8 -Xms256m -Xmx1024m -jar dist/NSO-HUYDAT.jar
