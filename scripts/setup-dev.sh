#!/bin/bash
# Forensic OS - Development Environment Setup
# Installs live-build and all required build dependencies
set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()  { echo -e "${CYAN}[STEP]${NC}  ${BOLD}$*${NC}"; }

echo ""
echo -e "${BOLD}${CYAN}====================================${NC}"
echo -e "${BOLD}${CYAN} Forensic OS - Dev Environment Setup${NC}"
echo -e "${BOLD}${CYAN}====================================${NC}"
echo ""

# -------------------------------------------------------------------
# Root check
# -------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root."
    echo -e "  Try: ${CYAN}sudo $0${NC}"
    exit 1
fi

# -------------------------------------------------------------------
# Detect distro
# -------------------------------------------------------------------
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${ID}"
    log_info "Detected distribution: ${PRETTY_NAME:-${DISTRO}}"
else
    log_warn "Could not detect distribution. Assuming Debian/Ubuntu."
    DISTRO="debian"
fi

# -------------------------------------------------------------------
# Install packages
# -------------------------------------------------------------------
log_step "Updating package lists..."
apt-get update -qq

log_step "Installing live-build and dependencies..."
PACKAGES=(
    # Core build system
    live-build
    debootstrap
    cdebootstrap

    # Required by live-build
    apt-utils
    dosfstools
    e2fsprogs
    grub-efi-amd64-bin
    grub-pc-bin
    mtools
    squashfs-tools
    xorriso
    syslinux
    syslinux-common
    syslinux-efi
    syslinux-utils
    isolinux
    memtest86+

    # Useful for development
    git
    curl
    wget
    gnupg
    ca-certificates
    apt-transport-https
    software-properties-common

    # Build utilities
    make
    rsync
    cpio
    genisoimage
)

apt-get install -y --no-install-recommends "${PACKAGES[@]}"

# -------------------------------------------------------------------
# Verify installation
# -------------------------------------------------------------------
log_step "Verifying installation..."

FAILED=0
for cmd in lb debootstrap xorriso mksquashfs; do
    if command -v "${cmd}" &>/dev/null; then
        log_info "  $(command -v "${cmd}") -> OK"
    else
        log_error "  ${cmd} -> NOT FOUND"
        FAILED=1
    fi
done

if [ "${FAILED}" -eq 1 ]; then
    log_error "Some required tools are missing. Check the output above."
    exit 1
fi

# -------------------------------------------------------------------
# Show versions
# -------------------------------------------------------------------
echo ""
log_info "Installed versions:"
echo "  live-build: $(lb --version 2>/dev/null || echo 'unknown')"
echo "  debootstrap: $(debootstrap --version 2>/dev/null || echo 'unknown')"
echo "  xorriso: $(xorriso --version 2>&1 | head -1 || echo 'unknown')"

echo ""
log_info "========================================="
log_info " Setup complete!"
log_info "========================================="
echo ""
echo -e "Next steps:"
echo -e "  1. ${CYAN}make build${NC}  - Build the ISO (requires root)"
echo -e "  2. ${CYAN}make usb${NC}    - Write ISO to USB drive"
echo ""
