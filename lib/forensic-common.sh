#!/usr/bin/env bash
# =============================================================================
# forensic-common.sh - Shared library for Forensic OS Toolkit
# =============================================================================
# Source this file from all forensic tools to get common functions, color
# constants, logging, and utility helpers.
# =============================================================================

# Prevent double-sourcing
[[ -n "${_FORENSIC_COMMON_LOADED:-}" ]] && return 0
_FORENSIC_COMMON_LOADED=1

# ---- Color Constants --------------------------------------------------------
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m'   # No Color / reset
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly BOLD=''
    readonly NC=''
fi

# ---- Global Defaults --------------------------------------------------------
FORENSIC_CASE_DIR="${FORENSIC_CASE_DIR:-/cases}"
FORENSIC_LOG_FILE="${FORENSIC_LOG_FILE:-}"
FORENSIC_VERBOSE="${FORENSIC_VERBOSE:-0}"

# ---- Logging Functions ------------------------------------------------------

# Internal helper: print a formatted log line.
_log() {
    local level_color="$1" level_tag="$2"
    shift 2
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    printf "${level_color}[%s] [%s]${NC} %s\n" "$ts" "$level_tag" "$msg" >&2
}

log_info() {
    _log "$BLUE" "INFO" "$@"
}

log_warn() {
    _log "$YELLOW" "WARN" "$@"
}

log_error() {
    _log "$RED" "ERROR" "$@"
}

log_success() {
    _log "$GREEN" "OK" "$@"
}

# ---- Privilege Check --------------------------------------------------------

require_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        log_error "This operation requires root privileges. Re-run with sudo."
        exit 1
    fi
}

# ---- Tool Availability ------------------------------------------------------

# check_tool <tool_name> [package_hint]
# Returns 0 if the tool is on PATH, 1 otherwise (with a warning).
check_tool() {
    local tool="$1"
    local hint="${2:-$1}"
    if ! command -v "$tool" &>/dev/null; then
        log_warn "Required tool '${tool}' is not installed (try: apt install ${hint})."
        return 1
    fi
    return 0
}

# ---- Case Directory ---------------------------------------------------------

# get_case_dir
# Returns the current case working directory. Honors FORENSIC_CASE_DIR env var.
# Creates the directory if it does not exist.
get_case_dir() {
    local case_dir="${FORENSIC_CASE_DIR:-/cases}"
    if [[ ! -d "$case_dir" ]]; then
        mkdir -p "$case_dir" 2>/dev/null || {
            log_error "Cannot create case directory: ${case_dir}"
            return 1
        }
    fi
    printf '%s' "$case_dir"
}

# ---- Hashing Utilities ------------------------------------------------------

# generate_hash <file> [algorithm]
# Prints the hex hash of <file> using the given algorithm (default: sha256).
generate_hash() {
    local file="$1"
    local algo="${2:-sha256}"

    if [[ ! -f "$file" ]]; then
        log_error "generate_hash: file not found: ${file}"
        return 1
    fi

    local cmd
    case "$algo" in
        md5)    cmd="md5sum"    ;;
        sha1)   cmd="sha1sum"   ;;
        sha256) cmd="sha256sum" ;;
        sha512) cmd="sha512sum" ;;
        *)
            log_error "generate_hash: unsupported algorithm: ${algo}"
            return 1
            ;;
    esac

    if ! check_tool "$cmd" "coreutils"; then
        return 1
    fi

    "$cmd" "$file" | awk '{print $1}'
}

# verify_hash <file> <expected_hash> [algorithm]
# Returns 0 if the computed hash matches expected_hash, 1 otherwise.
verify_hash() {
    local file="$1"
    local expected="$2"
    local algo="${3:-sha256}"

    local actual
    actual="$(generate_hash "$file" "$algo")" || return 1

    if [[ "$actual" == "$expected" ]]; then
        log_success "Hash verification PASSED for ${file} (${algo})"
        return 0
    else
        log_error "Hash verification FAILED for ${file} (${algo})"
        log_error "  Expected: ${expected}"
        log_error "  Actual:   ${actual}"
        return 1
    fi
}

# ---- Formatting Helpers -----------------------------------------------------

# format_size <bytes>
# Converts a byte count to a human-readable string (e.g. 1.5 GiB).
format_size() {
    local bytes="${1:-0}"
    if [[ "$bytes" -lt 1024 ]]; then
        printf '%d B' "$bytes"
    elif [[ "$bytes" -lt 1048576 ]]; then
        printf '%.1f KiB' "$(echo "scale=1; $bytes / 1024" | bc)"
    elif [[ "$bytes" -lt 1073741824 ]]; then
        printf '%.1f MiB' "$(echo "scale=1; $bytes / 1048576" | bc)"
    elif [[ "$bytes" -lt 1099511627776 ]]; then
        printf '%.2f GiB' "$(echo "scale=2; $bytes / 1073741824" | bc)"
    else
        printf '%.2f TiB' "$(echo "scale=2; $bytes / 1099511627776" | bc)"
    fi
}

# ---- Timestamp --------------------------------------------------------------

# timestamp
# Prints an ISO-8601 timestamp suitable for filenames.
timestamp() {
    date '+%Y%m%dT%H%M%S%z'
}

# ---- Audit Trail ------------------------------------------------------------

# audit_log <action_message>
# Appends a timestamped entry to the case audit log.
audit_log() {
    local msg="$*"
    local case_dir
    case_dir="$(get_case_dir)" || return 1

    local audit_file="${case_dir}/audit.log"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    local user
    user="$(whoami)"
    local host
    host="$(hostname)"

    printf '[%s] user=%s host=%s tool=%s action="%s"\n' \
        "$ts" "$user" "$host" "${FORENSIC_TOOL_NAME:-unknown}" "$msg" \
        >> "$audit_file" 2>/dev/null

    if [[ "$FORENSIC_VERBOSE" -eq 1 ]]; then
        log_info "AUDIT: ${msg}"
    fi
}
