#!/bin/bash
# Forensic OS - Write ISO to USB Device
# Uses dd with safety confirmations to prevent accidental data loss
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

# -------------------------------------------------------------------
# Validation
# -------------------------------------------------------------------
ISO_FILE="${1:-}"

if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root."
    echo -e "  Try: ${CYAN}sudo $0 <iso-file>${NC}"
    exit 1
fi

if [ -z "${ISO_FILE}" ]; then
    log_error "Usage: $0 <path-to-iso>"
    exit 1
fi

if [ ! -f "${ISO_FILE}" ]; then
    log_error "ISO file not found: ${ISO_FILE}"
    exit 1
fi

# -------------------------------------------------------------------
# List available USB devices
# -------------------------------------------------------------------
echo ""
echo -e "${BOLD}${CYAN}Forensic OS - USB Writer${NC}"
echo -e "${CYAN}========================${NC}"
echo ""

log_info "ISO file: ${ISO_FILE} ($(du -h "${ISO_FILE}" | cut -f1))"
echo ""

echo -e "${BOLD}Available removable block devices:${NC}"
echo "-----------------------------------"

DEVICES=()
while IFS= read -r line; do
    DEVICES+=("${line}")
done < <(lsblk -dpno NAME,SIZE,MODEL,TRAN 2>/dev/null | grep -E 'usb' || true)

if [ ${#DEVICES[@]} -eq 0 ]; then
    # Fallback: show all removable devices
    while IFS= read -r line; do
        DEVICES+=("${line}")
    done < <(lsblk -dpno NAME,SIZE,MODEL,RM 2>/dev/null | awk '$4 == "1" {print $1, $2, $3}' || true)
fi

if [ ${#DEVICES[@]} -eq 0 ]; then
    log_error "No removable USB devices detected."
    echo "  Insert a USB drive and try again."
    exit 1
fi

for i in "${!DEVICES[@]}"; do
    echo -e "  ${GREEN}[$((i+1))]${NC} ${DEVICES[$i]}"
done
echo ""

# -------------------------------------------------------------------
# Device selection
# -------------------------------------------------------------------
read -rp "Select device number (or 'q' to quit): " choice

if [ "${choice}" = "q" ] || [ "${choice}" = "Q" ]; then
    log_info "Aborted by user."
    exit 0
fi

if ! [[ "${choice}" =~ ^[0-9]+$ ]] || [ "${choice}" -lt 1 ] || [ "${choice}" -gt ${#DEVICES[@]} ]; then
    log_error "Invalid selection."
    exit 1
fi

TARGET_DEV=$(echo "${DEVICES[$((choice-1))]}" | awk '{print $1}')

# -------------------------------------------------------------------
# Safety confirmations
# -------------------------------------------------------------------
echo ""
echo -e "${RED}${BOLD}!!! WARNING !!!${NC}"
echo -e "${RED}All data on ${BOLD}${TARGET_DEV}${NC}${RED} will be permanently destroyed!${NC}"
echo ""

# Show device details
lsblk "${TARGET_DEV}" 2>/dev/null || true
echo ""

read -rp "Type the device name (e.g., /dev/sdb) to confirm: " confirm_dev

if [ "${confirm_dev}" != "${TARGET_DEV}" ]; then
    log_error "Device name does not match. Aborting for safety."
    exit 1
fi

echo ""
read -rp "Final confirmation - type 'YES' in uppercase to proceed: " final_confirm

if [ "${final_confirm}" != "YES" ]; then
    log_info "Aborted by user."
    exit 0
fi

# -------------------------------------------------------------------
# Unmount any mounted partitions
# -------------------------------------------------------------------
log_info "Unmounting partitions on ${TARGET_DEV}..."
for part in "${TARGET_DEV}"*; do
    umount "${part}" 2>/dev/null || true
done

# -------------------------------------------------------------------
# Write ISO
# -------------------------------------------------------------------
echo ""
log_info "Writing ISO to ${TARGET_DEV}..."
log_warn "Do NOT remove the USB drive until complete."
echo ""

dd if="${ISO_FILE}" of="${TARGET_DEV}" bs=4M status=progress oflag=sync conv=fsync

sync

echo ""
log_info "========================================="
log_info " USB write complete!"
log_info "========================================="
log_info "Device: ${TARGET_DEV}"
log_info "You can safely remove the USB drive now."
echo ""
