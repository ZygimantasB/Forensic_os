#!/usr/bin/env bash
# Tests for write-blocking configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PASS=0
FAIL=0

assert_file_exists() {
    local desc="$1" path="$2"
    if [[ -f "$path" ]]; then
        echo "  PASS: $desc"
        ((PASS++))
    else
        echo "  FAIL: $desc (file not found: $path)"
        ((FAIL++))
    fi
}

assert_contains() {
    local desc="$1" needle="$2" file="$3"
    if grep -q "$needle" "$file" 2>/dev/null; then
        echo "  PASS: $desc"
        ((PASS++))
    else
        echo "  FAIL: $desc ('$needle' not found in $file)"
        ((FAIL++))
    fi
}

echo "=== Testing write-block configuration ==="

# Test udev rules exist
echo "-- udev rules --"
UDEV_RULES="$SCRIPT_DIR/../config/udev/99-forensic-writeblock.rules"
assert_file_exists "udev rules file exists" "$UDEV_RULES"
assert_contains "rules reference block devices" "block" "$UDEV_RULES"

# Test systemd service exists
echo "-- systemd service --"
WB_SERVICE="$SCRIPT_DIR/../config/systemd/forensic-writeblock.service"
assert_file_exists "writeblock service exists" "$WB_SERVICE"
assert_contains "service has ExecStart" "ExecStart" "$WB_SERVICE"

AUDIT_SERVICE="$SCRIPT_DIR/../config/systemd/forensic-audit.service"
assert_file_exists "audit service exists" "$AUDIT_SERVICE"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
