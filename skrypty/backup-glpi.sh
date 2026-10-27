#!/usr/bin/env bash
#
# backup-glpi.sh - kopia zapasowa GLPI na srv-helpdesk
# robi dump bazy + archiwum katalogu files
#
# haslo do mysql w /opt/backup/.my.cnf (nie w skrypcie)
# uruchamiac przez sudo - inaczej tar wywala Permission denied
# na plikach www-data (sesje, oauth.pem)
#
# cron: 0 2 * * * /opt/backup/backup-glpi.sh >> /opt/backup/backup.log 2>&1

set -euo pipefail

DB_NAME="glpidb"
GLPI_FILES="/var/www/html/glpi/files"
BACKUP_DIR="/opt/backup/glpi"
MYSQL_CNF="/opt/backup/.my.cnf"
RETENCJA_DNI=14   # 0 = wylacz rotacje

DATA="$(date +%Y-%m-%d_%H%M%S)"
DUMP="${BACKUP_DIR}/${DB_NAME}_${DATA}.sql.gz"
FILES="${BACKUP_DIR}/glpi-files_${DATA}.tar.gz"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# przy bledzie usun niedokonczone pliki, zeby nie zostawic uszkodzonej kopii
sprzatnij() {
  log "BLAD - backup przerwany, usuwam niepelne pliki"
  rm -f "$DUMP" "$FILES"
}
trap sprzatnij ERR

mkdir -p "$BACKUP_DIR"
log "Start backupu GLPI"

# single-transaction zeby nie blokowac tabel InnoDB
mariadb-dump --defaults-extra-file="$MYSQL_CNF" --single-transaction "$DB_NAME" \
  | gzip > "$DUMP"
log "  baza  -> $(basename "$DUMP")"

tar -czf "$FILES" -C "$(dirname "$GLPI_FILES")" "$(basename "$GLPI_FILES")"
log "  pliki -> $(basename "$FILES")"

if [ "$RETENCJA_DNI" -gt 0 ]; then
  find "$BACKUP_DIR" -type f -name '*.gz' -mtime +"$RETENCJA_DNI" -delete
fi

trap - ERR

ROZMIAR="$(du -ch "$DUMP" "$FILES" | awk 'END {print $1}')"
log "Zakonczono. Laczny rozmiar kopii: ${ROZMIAR}"
