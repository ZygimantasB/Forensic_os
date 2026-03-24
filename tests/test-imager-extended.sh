#!/usr/bin/env bash
# =============================================================================
# test-imager-extended.sh - Extended tests for forensic-imager tool
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

IMAGER_TOOL="$SCRIPT_DIR/../tools/forensic-imager"

test_start "forensic-imager extended tests"

# ---- Test: tool is executable ------------------------------------------------
test_section "Tool accessibility"
assert_executable "forensic-imager is executable" "$IMAGER_TOOL"

# ---- Test: help/usage output ------------------------------------------------
test_section "Help and usage output"

output=$("$IMAGER_TOOL" -h 2>&1) || true
assert_contains "help shows Usage header" "Usage" "$output"
assert_contains "help mentions source option" "SOURCE" "$output"
assert_contains "help mentions output option" "OUTPUT" "$output"
assert_contains "help mentions raw format" "raw" "$output"
assert_contains "help mentions ewf format" "ewf" "$output"

# ---- Test: missing source error ---------------------------------------------
test_section "Missing source"

output=$("$IMAGER_TOOL" -o "$TEST_TMPDIR/out.img" 2>&1); rc=$?; true
assert_contains "missing source shows error" "Source" "$output"
assert_neq "missing source exits non-zero" "0" "$rc"

# ---- Test: missing output error ---------------------------------------------
test_section "Missing output"

# Create a small test file to use as source so we get past source validation
create_test_file "$TEST_TMPDIR/fake_source.bin" "fake disk data for testing"

output=$("$IMAGER_TOOL" -s "$TEST_TMPDIR/fake_source.bin" 2>&1); rc=$?; true
assert_contains "missing output shows error" "Output" "$output"
assert_neq "missing output exits non-zero" "0" "$rc"

# ---- Test: nonexistent source error -----------------------------------------
test_section "Nonexistent source"

output=$("$IMAGER_TOOL" -s /nonexistent/device -o "$TEST_TMPDIR/out.img" 2>&1); rc=$?; true
assert_contains "nonexistent source shows error" "Source does not exist" "$output"
assert_neq "nonexistent source exits non-zero" "0" "$rc"

# ---- Test: invalid format error ---------------------------------------------
test_section "Invalid format"

output=$("$IMAGER_TOOL" -s "$TEST_TMPDIR/fake_source.bin" -o "$TEST_TMPDIR/out.img" -f qcow2 2>&1); rc=$?; true
assert_contains "invalid format shows error" "Unsupported format" "$output"
assert_neq "invalid format exits non-zero" "0" "$rc"

# ---- Test: argument validation works up to require_root check ---------------
test_section "Argument validation with valid args (non-root)"

# With a valid source file, valid output, and valid format, the tool should
# proceed past argument validation and fail at require_root (unless we are root)
if [[ $EUID -eq 0 ]]; then
    skip_test "validation reaches require_root" "running as root, would proceed to imaging"
else
    output=$("$IMAGER_TOOL" -s "$TEST_TMPDIR/fake_source.bin" -o "$TEST_TMPDIR/subdir/out.img" -f raw 2>&1); rc=$?; true
    # Should fail at require_root with an error about root/sudo
    assert_contains "valid args fail at root check" "root" "$output"
    assert_neq "valid args exit non-zero (not root)" "0" "$rc"
fi

# ---- Skip: actual imaging (requires root + block device) --------------------
test_section "Actual imaging (skipped)"

skip_test "image a block device (raw format)" "requires root privileges and a block device"
skip_test "image a block device (ewf format)" "requires root privileges, block device, and ewf-tools"

test_finish
