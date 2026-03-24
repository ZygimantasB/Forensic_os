#!/bin/bash
# Forensic OS - ISO Build Script
# Wraps live-build with validation, logging, and error handling
set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
LIVEBUILD_DIR="${PROJECT_ROOT}/config/live-build"

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()  { echo -e "${CYAN}[STEP]${NC}  ${BOLD}$*${NC}"; }

# -------------------------------------------------------------------
# Pre-flight checks
# -------------------------------------------------------------------
preflight() {
    log_step "Running pre-flight checks..."

    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root (required by live-build)."
        echo -e "  Try: ${CYAN}sudo make build${NC}"
        exit 1
    fi

    local missing=()
    for cmd in lb debootstrap; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${cmd}")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing[*]}"
        echo -e "  Run: ${CYAN}make setup${NC} to install dependencies."
        exit 1
    fi

    if [ ! -d "${LIVEBUILD_DIR}/auto" ]; then
        log_error "live-build auto/ directory not found at ${LIVEBUILD_DIR}/auto"
        exit 1
    fi

    log_info "Pre-flight checks passed."
}

# -------------------------------------------------------------------
# Build
# -------------------------------------------------------------------
do_build() {
    cd "${LIVEBUILD_DIR}"

    log_step "Configuring live-build..."
    lb config
    log_info "Configuration complete."

    log_step "Building ISO image (this will take a while)..."
    lb build

    # Find the resulting ISO
    local iso_file
    iso_file=$(find . -maxdepth 1 -name "*.iso" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')

    if [ -n "${iso_file}" ]; then
        local iso_size
        iso_size=$(du -h "${iso_file}" | cut -f1)
        local iso_sha256
        iso_sha256=$(sha256sum "${iso_file}" | awk '{print $1}')

        echo ""
        log_info "========================================="
        log_info " BUILD SUCCESSFUL"
        log_info "========================================="
        log_info "ISO:    ${iso_file}"
        log_info "Size:   ${iso_size}"
        log_info "SHA256: ${iso_sha256}"
        echo ""
        echo -e "Write to USB: ${CYAN}make usb${NC}"
    else
        log_error "Build appeared to succeed but no ISO file was found."
        exit 1
    fi
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
main() {
    echo ""
    echo -e "${BOLD}${CYAN}==============================${NC}"
    echo -e "${BOLD}${CYAN} Forensic OS - ISO Builder${NC}"
    echo -e "${BOLD}${CYAN}==============================${NC}"
    echo ""

    preflight
    do_build
}

main "$@"
