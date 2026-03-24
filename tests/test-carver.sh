#!/usr/bin/env bash
# =============================================================================
# test-carver.sh - Tests for forensic-carver tool
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

TOOL="$SCRIPT_DIR/../tools/forensic-carver"

test_start "forensic-carver tests"

# =============================================================================
test_section "Help and usage output"
# =============================================================================

output=$("$TOOL" -h 2>&1 || true)
assert_contains "Help flag shows usage" "Usage" "$output"
assert_contains "Help mentions source option" "-s SOURCE" "$output"
assert_contains "Help mentions output option" "-o OUTPUT" "$output"
assert_contains "Help mentions tool option" "-t TOOL" "$output"

# =============================================================================
test_section "Missing required arguments"
# =============================================================================

output=$("$TOOL" 2>&1 || true)
rc=0; "$TOOL" >/dev/null 2>&1 || rc=$?
assert_exit_code "Missing all args exits non-zero" "1" "$rc"
assert_contains "Missing source reports error" "Source" "$output"

output=$("$TOOL" -s /tmp/fake_source 2>&1 || true)
rc=0; "$TOOL" -s /tmp/fake_source >/dev/null 2>&1 || rc=$?
assert_exit_code "Missing output dir exits non-zero" "1" "$rc"
assert_contains "Missing output dir reports error" "Output" "$output"

# =============================================================================
test_section "Invalid tool name"
# =============================================================================

# Create a dummy source so we get past source validation
dummy_source="$TEST_TMPDIR/dummy.img"
dd if=/dev/zero of="$dummy_source" bs=1k count=1 2>/dev/null

output=$("$TOOL" -s "$dummy_source" -o "$TEST_TMPDIR/out" -t badtool 2>&1 || true)
rc=0; "$TOOL" -s "$dummy_source" -o "$TEST_TMPDIR/out" -t badtool >/dev/null 2>&1 || rc=$?
assert_exit_code "Invalid tool name exits non-zero" "1" "$rc"
assert_contains "Unsupported tool error message" "Unsupported tool" "$output"

# =============================================================================
test_section "Source existence validation"
# =============================================================================

output=$("$TOOL" -s /nonexistent/path.img -o "$TEST_TMPDIR/out" 2>&1 || true)
rc=0; "$TOOL" -s /nonexistent/path.img -o "$TEST_TMPDIR/out" >/dev/null 2>&1 || rc=$?
assert_exit_code "Nonexistent source exits non-zero" "1" "$rc"
assert_contains "Nonexistent source reports error" "does not exist" "$output"

# =============================================================================
test_section "Executable check"
# =============================================================================

assert_executable "forensic-carver is executable" "$TOOL"

# =============================================================================
test_section "Actual carving (requires foremost/scalpel/photorec + root)"
# =============================================================================

skip_test "Foremost carving" "requires foremost tool and root privileges"
skip_test "Scalpel carving" "requires scalpel tool and root privileges"
skip_test "PhotoRec carving" "requires photorec tool and root privileges"

test_finish
