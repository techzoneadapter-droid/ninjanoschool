#!/bin/sh
# Executed inside the private MariaDB container by the Windows setup script.
set -eu
db() {
  mariadb --user="$MARIADB_USER" --password="$MARIADB_PASSWORD" "$@"
}
game_count="$(db -N -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='nsohuyda_data'")"
account_count="$(db -N -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='nsohuyda_account'")"
if [ "$game_count" -gt 0 ] || [ "$account_count" -gt 0 ]; then
  if [ "$game_count" -ge 12 ] && [ "$account_count" -ge 6 ]; then
    echo "Existing local databases detected; never overwriting player or game data."
    exit 0
  fi
  echo "ERROR: partial database initialization detected. No automatic reset permitted." >&2
  exit 3
fi
test -s /tmp/nso-game-data.sql
test -s /tmp/nso-account-schema.sql
test -s /tmp/nso-demo-account.sql
echo "Initializing game reference tables ..."
db nsohuyda_data < /tmp/nso-game-data.sql
echo "Creating EMPTY account schema and one new offline-only test account ..."
db nsohuyda_account < /tmp/nso-account-schema.sql
db nsohuyda_account < /tmp/nso-demo-account.sql
game_count="$(db -N -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='nsohuyda_data'")"
account_count="$(db -N -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='nsohuyda_account'")"
player_count="$(db -N -e "SELECT COUNT(*) FROM nsohuyda_account.player")"
if [ "$game_count" -lt 12 ] || [ "$account_count" -lt 6 ] || [ "$player_count" -ne 1 ]; then
  echo "ERROR: offline database verification failed" >&2
  exit 4
fi
echo "OFFLINE DB READY: game tables=$game_count, account tables=$account_count, NEW local accounts=$player_count"
rm -f /tmp/nso-game-data.sql /tmp/nso-account-schema.sql /tmp/nso-demo-account.sql
