#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

CPU_WARN="${CPU_WARN:-80}"
MEM_WARN="${MEM_WARN:-80}"
DISK_WARN="${DISK_WARN:-80}"

PORTS_FILE="${PROJECT_ROOT}/config/ports.conf"
PROCESSES_FILE="${PROJECT_ROOT}/config/processes.conf"
REPORT_FILE="${REPORT_DIR}/system_check_$(date '+%Y%m%d_%H%M%S').txt"
RUN_LOG="${LOG_DIR}/system_check.log"

exec > >(tee -a "${RUN_LOG}") 2>&1

status_by_threshold() {
    local value="$1"
    local threshold="$2"
    if (( value >= threshold )); then
        echo "WARN"
    else
        echo "OK"
    fi
}

get_cpu_usage() {
    local cpu user nice system idle iowait irq softirq steal guest guest_nice
    local total1 idle1 total2 idle2 diff_total diff_idle

    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle1=$((idle + iowait))

    sleep 1

    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle2=$((idle + iowait))

    diff_total=$((total2 - total1))
    diff_idle=$((idle2 - idle1))

    if (( diff_total == 0 )); then
        echo 0
    else
        echo $(( (100 * (diff_total - diff_idle)) / diff_total ))
    fi
}

get_mem_usage() {
    local total available
    total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
    available=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)

    if [[ -z "${available}" ]]; then
        available=$(awk '
            /MemFree:/ {free=$2}
            /Buffers:/ {buffers=$2}
            /^Cached:/ {cached=$2}
            END {print free+buffers+cached}
        ' /proc/meminfo)
    fi

    echo $(( (100 * (total - available)) / total ))
}

check_ports() {
    echo
    echo "== TCP Port Check =="

    if [[ ! -f "${PORTS_FILE}" ]]; then
        echo "SKIP ports config not found: ${PORTS_FILE}"
        return
    fi

    while read -r host port name; do
        [[ -z "${host:-}" || "${host:0:1}" == "#" ]] && continue

        if timeout 2 bash -c "</dev/tcp/${host}/${port}" >/dev/null 2>&1; then
            printf "%-10s %-18s %-8s %s\n" "OK" "${host}:${port}" "${name}" "reachable"
        else
            printf "%-10s %-18s %-8s %s\n" "WARN" "${host}:${port}" "${name}" "unreachable"
        fi
    done < "${PORTS_FILE}"
}

check_processes() {
    echo
    echo "== Process Check =="

    if [[ ! -f "${PROCESSES_FILE}" ]]; then
        echo "SKIP processes config not found: ${PROCESSES_FILE}"
        return
    fi

    while read -r process; do
        [[ -z "${process:-}" || "${process:0:1}" == "#" ]] && continue

        if pgrep -x "${process}" >/dev/null 2>&1; then
            printf "%-10s %-20s %s\n" "OK" "${process}" "running"
        else
            printf "%-10s %-20s %s\n" "WARN" "${process}" "not running"
        fi
    done < "${PROCESSES_FILE}"
}

main() {
    local cpu_usage mem_usage hostname_value ip_value

    hostname_value=$(hostname)
    ip_value=$(hostname -I 2>/dev/null | awk '{print $1}')
    cpu_usage=$(get_cpu_usage)
    mem_usage=$(get_mem_usage)

    {
        echo "=========================================="
        echo "        LightOps System Check Report"
        echo "=========================================="
        echo "Time     : $(timestamp)"
        echo "Hostname : ${hostname_value}"
        echo "IP       : ${ip_value:-N/A}"
        echo "Kernel   : $(uname -r)"
        echo "Uptime   : $(uptime -p 2>/dev/null || uptime)"
        echo

        echo "== Resource Usage =="
        printf "%-10s %3s%%   threshold=%s%%\n" \
            "$(status_by_threshold "${cpu_usage}" "${CPU_WARN}")" \
            "${cpu_usage}" "${CPU_WARN}"

        printf "%-10s %3s%%   threshold=%s%%\n" \
            "$(status_by_threshold "${mem_usage}" "${MEM_WARN}")" \
            "${mem_usage}" "${MEM_WARN}"

        echo
        echo "== Disk Usage =="
        df -P -x tmpfs -x devtmpfs | awk -v threshold="${DISK_WARN}" '
            NR == 1 {
                printf "%-10s %-25s %-10s %-10s\n", "STATUS", "MOUNT", "USED", "FILESYSTEM"
                next
            }
            {
                used=$5
                gsub("%","",used)
                status=(used >= threshold ? "WARN" : "OK")
                printf "%-10s %-25s %-10s %-10s\n", status, $6, $5, $1
            }
        '

        check_ports
        check_processes

        echo
        echo "Report saved to: ${REPORT_FILE}"
    } | tee "${REPORT_FILE}"
}

main "$@"
