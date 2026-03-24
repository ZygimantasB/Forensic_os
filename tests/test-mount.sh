#!/usr/bin/env bash
# Tests for forensic-mount tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

MOUNT_TOOL="$SCRIPT_DIR/../tools/forensic-mount"

test_start "forensic-mount tests"

# ---- Sanity checks -----------------------------------------------------------
test_section "Sanity checks"

assert_file_exists "forensic-mount tool exists" "$MOUNT_TOOL"
assert_executable "forensic-mount is executable" "$MOUNT_TOOL"

shebang=$(head -1 "$MOUNT_TOOL")
assert_contains "has proper shebang" "#!/usr/bin/env bash" "$shebang"

# ---- Help / usage output -----------------------------------------------------
test_section "Help / usage output"

help_output=$("$MOUNT_TOOL" -h 2>&1 || true)
assert_contains "help shows Usage" "Usage" "$help_output"
assert_contains "help mentions -s flag" "SOURCE" "$help_output"
assert_contains "help mentions -m flag" "MOUNTPOINT" "$help_output"
assert_contains "help mentions -l flag" "List" "$help_output"
assert_contains "help mentions -u flag" "Unmount" "$help_output"
assert_contains "help mentions evidence" "evidence" "$help_output"

# ---- List mode works without root --------------------------------------------
test_section "List mode (-l)"

list_output=$("$MOUNT_TOOL" -l 2>&1)
list_rc=$?
assert_exit_code "list mode exits successfully" "0" "$list_rc"
assert_contains "list output mentions mounted" "mount\|SOURCE\|MOUNTPOINT" "$list_output"

# ---- Argument validation: missing -s -----------------------------------------
test_section "Argument validation"

no_s_rc=0
no_s_output=$("$MOUNT_TOOL" 2>&1) || no_s_rc=$?
assert_eq "no args fails with non-zero exit" "1" "$no_s_rc"
assert_contains "error mentions source required" "Source\|source\|-s\|required" "$no_s_output"

# ---- Missing source error ----------------------------------------------------
test_section "Missing source error"

# Provide -s with a nonexistent path
nonexist_rc=0
nonexist_output=$("$MOUNT_TOOL" -s "$TEST_TMPDIR/nonexistent_image.img" 2>&1) || nonexist_rc=$?
# This should fail because either it requires root before checking source,
# or it finds source doesn't exist. Either way, non-zero exit.
assert_eq "nonexistent source fails" "1" "$nonexist_rc"
assert_contains "error about source" "not exist\|not found\|root\|Source\|FATAL" "$nonexist_output"

# ---- Actual mount operations require root ------------------------------------
test_section "Mount operations (require root)"

if [[ "$(id -u)" -eq 0 ]]; then
    # Create a small test image
    test_img="$TEST_TMPDIR/test_evidence.img"
    create_test_image "$test_img" 1
    # We could test actual mounting here, but skip for safety in test environments
    skip_test "actual mount with real image" "skipped in automated test environment"
else
    skip_test "mount a device/image" "requires root privileges"
    skip_test "unmount an evidence volume" "requires root privileges"
    skip_test "verify read-only mount options" "requires root privileges"
fi

test_finish
