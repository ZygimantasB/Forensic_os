#!/usr/bin/env bash
# Tests for forensic-imager tool (non-destructive tests only)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

IMAGER="$SCRIPT_DIR/../tools/forensic-imager"

test_start "forensic-imager tool"

# ---- Help ----
test_section "help and usage"
output=$("$IMAGER" -h 2>&1)
assert_contains "shows Usage" "Usage" "$output"
assert_contains "mentions source" "source\|SOURCE" "$output"
assert_contains "mentions output" "output\|OUTPUT" "$output"
assert_contains "mentions format" "raw\|ewf" "$output"

# ---- Argument validation ----
test_section "argument validation"

output=$("$IMAGER" 2>&1)
rc=$?
assert_neq "no args shows error" "0" "$rc"

output=$("$IMAGER" -s /dev/null 2>&1)
rc=$?
assert_neq "missing output fails" "0" "$rc"

output=$("$IMAGER" -o /tmp/test.img 2>&1)
rc=$?
assert_neq "missing source fails" "0" "$rc"

output=$("$IMAGER" -s /nonexistent/device -o /tmp/test.img 2>&1)
rc=$?
assert_neq "nonexistent source fails" "0" "$rc"
assert_contains "error message for bad source" "not exist\|not found\|error" "$output"

output=$("$IMAGER" -s /dev/null -o /tmp/test.img -f invalid_format 2>&1)
rc=$?
assert_neq "invalid format fails" "0" "$rc"
assert_contains "error message for bad format" "unsupported\|format\|raw\|ewf" "$output"

# ---- Root requirement ----
test_section "root requirement"
if [[ "$(id -u)" -ne 0 ]]; then
    # Create a test source file
    create_test_file "$TEST_TMPDIR/source.bin" "test source data"
    output=$("$IMAGER" -s "$TEST_TMPDIR/source.bin" -o "$TEST_TMPDIR/output.img" 2>&1)
    rc=$?
    assert_neq "non-root user is rejected" "0" "$rc"
    assert_contains "mentions root/sudo" "root\|sudo\|privilege" "$output"
else
    skip_test "root rejection" "running as root"
fi

# ---- Tool properties ----
test_section "tool properties"
assert_executable "imager is executable" "$IMAGER"
shebang=$(head -1 "$IMAGER")
assert_contains "has bash shebang" "bash" "$shebang"

test_finish
