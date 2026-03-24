#!/usr/bin/env bash
# Tests for write-blocking configuration files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

test_start "write-blocking configuration"

PROJECT_ROOT="$SCRIPT_DIR/.."

# ---- udev rules ----
test_section "udev rules"
UDEV_RULES="$PROJECT_ROOT/config/udev/99-forensic-writeblock.rules"
assert_file_exists "udev rules file exists" "$UDEV_RULES"
assert_file_not_empty "udev rules file is not empty" "$UDEV_RULES"
assert_file_contains "rules reference block subsystem" "block" "$UDEV_RULES"
assert_file_contains "rules use blockdev --setro" "setro" "$UDEV_RULES"
assert_file_contains "rules handle USB devices" "usb\|USB" "$UDEV_RULES"
assert_file_contains "rules handle SATA devices" "ata\|scsi\|SATA" "$UDEV_RULES"
assert_file_contains "rules handle NVMe devices" "nvme\|NVMe" "$UDEV_RULES"
assert_file_contains "rules log to audit file" "forensic-audit" "$UDEV_RULES"
assert_file_contains "rules detect boot device" "findmnt" "$UDEV_RULES"

# ---- systemd writeblock service ----
test_section "systemd writeblock service"
WB_SERVICE="$PROJECT_ROOT/config/systemd/forensic-writeblock.service"
assert_file_exists "writeblock service exists" "$WB_SERVICE"
assert_file_not_empty "writeblock service is not empty" "$WB_SERVICE"
assert_file_contains "service has Unit section" "\\[Unit\\]" "$WB_SERVICE"
assert_file_contains "service has Service section" "\\[Service\\]" "$WB_SERVICE"
assert_file_contains "service has Install section" "\\[Install\\]" "$WB_SERVICE"
assert_file_contains "service has ExecStart" "ExecStart" "$WB_SERVICE"
assert_file_contains "service has description" "Description" "$WB_SERVICE"
assert_file_contains "service uses blockdev" "blockdev\|setro" "$WB_SERVICE"

# ---- systemd audit service ----
test_section "systemd audit service"
AUDIT_SERVICE="$PROJECT_ROOT/config/systemd/forensic-audit.service"
assert_file_exists "audit service exists" "$AUDIT_SERVICE"
assert_file_not_empty "audit service is not empty" "$AUDIT_SERVICE"
assert_file_contains "audit service has Unit section" "\\[Unit\\]" "$AUDIT_SERVICE"
assert_file_contains "audit service has ExecStart" "ExecStart" "$AUDIT_SERVICE"
assert_file_contains "audit service references audit log" "forensic-audit" "$AUDIT_SERVICE"
assert_file_contains "audit service restarts" "Restart" "$AUDIT_SERVICE"

# ---- Boot protection ----
test_section "boot device protection"
assert_file_contains "udev rules exclude boot device" "BOOT_DEV\|findmnt" "$UDEV_RULES"
assert_file_contains "writeblock service excludes boot" "BOOT_DEV\|findmnt" "$WB_SERVICE"

test_finish
