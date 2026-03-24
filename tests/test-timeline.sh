#!/usr/bin/env bash
# =============================================================================
# test-timeline.sh - Tests for forensic-timeline tool
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

TOOL="$SCRIPT_DIR/../tools/forensic-timeline"

test_start "forensic-timeline tests"

# =============================================================================
test_section "Help and usage output"
# =============================================================================

output=$("$TOOL" -h 2>&1 || true)
assert_contains "Help flag shows usage" "Usage" "$output"
assert_contains "Help mentions source option" "-s SOURCE" "$output"
assert_contains "Help mentions output option" "-o OUTPUT" "$output"
assert_contains "Help mentions format option" "-f FORMAT" "$output"
assert_contains "Help mentions csv format" "csv" "$output"
assert_contains "Help mentions json format" "json" "$output"

# =============================================================================
test_section "Missing required arguments"
# =============================================================================

output=$("$TOOL" 2>&1 || true)
rc=0; "$TOOL" >/dev/null 2>&1 || rc=$?
assert_exit_code "Missing all args exits non-zero" "1" "$rc"
assert_contains "Missing source reports error" "Source" "$output"

# =============================================================================
test_section "Nonexistent source"
# =============================================================================

output=$("$TOOL" -s /nonexistent/disk.img 2>&1 || true)
rc=0; "$TOOL" -s /nonexistent/disk.img >/dev/null 2>&1 || rc=$?
assert_exit_code "Nonexistent source exits non-zero" "1" "$rc"
assert_contains "Nonexistent source reports error" "does not exist" "$output"

# =============================================================================
test_section "Invalid format"
# =============================================================================

# Create a dummy source file to pass source validation
dummy_source="$TEST_TMPDIR/dummy.img"
dd if=/dev/zero of="$dummy_source" bs=1k count=1 2>/dev/null

output=$("$TOOL" -s "$dummy_source" -f xml 2>&1 || true)
rc=0; "$TOOL" -s "$dummy_source" -f xml >/dev/null 2>&1 || rc=$?
assert_exit_code "Invalid format exits non-zero" "1" "$rc"
assert_contains "Invalid format reports error" "Unsupported format" "$output"

# =============================================================================
test_section "Argument parsing with all flags"
# =============================================================================

# The tool will fail because fls/plaso are not installed, but we can verify
# it gets past argument parsing by checking it does NOT complain about args
output=$("$TOOL" -s "$dummy_source" -o "$TEST_TMPDIR/timeline.csv" -f csv -t filesystem -S 2025-01-01 -E 2025-12-31 -v 2>&1 || true)
assert_contains "Argument parsing accepts all flags" "Timeline Analysis" "$output"
assert_contains "Source is reported in output" "Source" "$output"

# =============================================================================
test_section "Executable check"
# =============================================================================

assert_executable "forensic-timeline is executable" "$TOOL"

# =============================================================================
test_section "Actual timeline generation (requires fls/plaso)"
# =============================================================================

skip_test "Plaso timeline generation" "requires log2timeline.py (plaso) to be installed"
skip_test "Sleuth Kit fls timeline generation" "requires fls and mactime (sleuthkit) to be installed"

test_finish
