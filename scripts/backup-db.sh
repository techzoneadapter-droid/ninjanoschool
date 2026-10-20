#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p backups
backup="backups/nso-$(date +%Y%m%d-%H%M%S).sql"
# Dump both databases transactionally. Redirect directly to a locally ignored backup.
docker compose exec -T db sh -c 'exec mariadb-dump --user=root --password="$MARIADB_ROOT_PASSWORD" --single-transaction --routines --events --databases nsohuyda_data nsohuyda_account' > "$backup"
chmod 600 "$backup"
echo "Saved private database backup: $backup"
