#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

MYSQL_CNF="${MYSQL_CNF:-${PROJECT_ROOT}/config/mysql.cnf}"
MYSQL_DATABASE="${MYSQL_DATABASE:-lightops_demo}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
RUN_LOG="${LOG_DIR}/mysql_backup.log"

mkdir -p "${BACKUP_DIR}"
exec >> "${RUN_LOG}" 2>&1

cleanup_partial() {
    if [[ -n "${TMP_FILE:-}" && -f "${TMP_FILE}" ]]; then
        rm -f "${TMP_FILE}"
    fi
}

trap cleanup_partial EXIT

main() {
    local ts final_file

    require_command mysqldump || exit 10
    require_command gzip || exit 11
    require_command find || exit 12

    if [[ ! -f "${MYSQL_CNF}" ]]; then
        log_error "MySQL client config not found: ${MYSQL_CNF}"
        exit 20
    fi

    if [[ ! -r "${MYSQL_CNF}" ]]; then
        log_error "MySQL client config is not readable: ${MYSQL_CNF}"
        exit 21
    fi

    ts=$(date '+%Y%m%d_%H%M%S')
    TMP_FILE="${BACKUP_DIR}/${MYSQL_DATABASE}_${ts}.sql"
    final_file="${TMP_FILE}.gz"

    log_info "Start backup database=${MYSQL_DATABASE}"

    if ! mysqldump \
        --defaults-extra-file="${MYSQL_CNF}" \
        --single-transaction \
        --quick \
        --triggers \
        --no-tablespaces \
        "${MYSQL_DATABASE}" > "${TMP_FILE}"; then
        log_error "mysqldump failed"
        exit 30
    fi

    if ! gzip "${TMP_FILE}"; then
        log_error "gzip failed"
        exit 31
    fi

    TMP_FILE=""

    if [[ ! -s "${final_file}" ]]; then
        log_error "Backup file is empty: ${final_file}"
        exit 32
    fi

    log_info "Backup completed: ${final_file}"

    log_info "Delete backups older than ${RETENTION_DAYS} days"
    find "${BACKUP_DIR}" \
        -type f \
        -name "${MYSQL_DATABASE}_*.sql.gz" \
        -mtime "+${RETENTION_DAYS}" \
        -print \
        -delete

    log_info "Backup task finished"
}

main "$@"
