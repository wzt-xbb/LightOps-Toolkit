#!/usr/bin/env bash

 set -u

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/config/lightops.env"

if [[ -f "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}"
fi

LOG_DIR="${LOG_DIR:-${PROJECT_ROOT}/logs}"
REPORT_DIR="${REPORT_DIR:-${PROJECT_ROOT}/reports}"
BACKUP_DIR="${BACKUP_DIR:-${PROJECT_ROOT}/backups/mysql}"

mkdir -p "${LOG_DIR}" "${REPORT_DIR}" "${BACKUP_DIR}"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
    echo "$(timestamp) [INFO] $*"
}

Log_warn() {
    echo "$(timestamp) [WARN] $*" >&2
}

log_error() {
    echo "$(timestamp) [ERROR] $*" >&2
}

require_command() {
    local cmd="$1"
    if ! command -v "${cmd}" >/dev/null 2>&1;then
        log_error "Required command not found: ${cmd}"
        return 1
    fi
}