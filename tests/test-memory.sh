#!/usr/bin/env bash
# =============================================================================
# test-memory.sh - Tests for forensic-memory tool
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

MEMORY_TOOL="$SCRIPT_DIR/../tools/forensic-memory"

test_start "forensic-memory tests"

# ---- Test: tool is executable ------------------------------------------------
test_section "Tool accessibility"
assert_executable "forensic-memory is executable" "$MEMORY_TOOL"

# ---- Test: help/usage output ------------------------------------------------
test_section "Help and usage output"

output=$("$MEMORY_TOOL" -h 2>&1) || true
assert_contains "help shows Usage header" "Usage" "$output"
assert_contains "help mentions acquire command" "acquire" "$output"
assert_contains "help mentions analyze command" "analyze" "$output"

output=$("$MEMORY_TOOL" acquire -h 2>&1) || true
assert_contains "acquire -h shows usage" "Usage" "$output"

output=$("$MEMORY_TOOL" analyze -h 2>&1) || true
assert_contains "analyze -h shows usage" "Usage" "$output"

# ---- Test: missing subcommand error -----------------------------------------
test_section "Missing subcommand"

output=$("$MEMORY_TOOL" 2>&1); rc=$?; true
assert_contains "no args shows usage" "Usage" "$output"
assert_neq "no args exits non-zero" "0" "$rc"

# ---- Test: invalid subcommand error -----------------------------------------
test_section "Invalid subcommand"

output=$("$MEMORY_TOOL" boguscmd 2>&1); rc=$?; true
assert_contains "invalid subcommand shows error" "Unknown command" "$output"
assert_neq "invalid subcommand exits non-zero" "0" "$rc"

# ---- Test: acquire missing output error -------------------------------------
test_section "Acquire missing output"

output=$("$MEMORY_TOOL" acquire 2>&1); rc=$?; true
assert_contains "acquire without -o shows error" "Output" "$output"
assert_neq "acquire without -o exits non-zero" "0" "$rc"

# ---- Test: analyze missing input error --------------------------------------
test_section "Analyze missing input"

output=$("$MEMORY_TOOL" analyze 2>&1); rc=$?; true
assert_contains "analyze without -i shows error" "Input" "$output"
assert_neq "analyze without -i exits non-zero" "0" "$rc"

# ---- Test: analyze with nonexistent input file ------------------------------
test_section "Analyze nonexistent input file"

output=$("$MEMORY_TOOL" analyze -i /nonexistent/memory.raw 2>&1); rc=$?; true
assert_contains "analyze nonexistent file shows error" "not found" "$output"
assert_neq "analyze nonexistent file exits non-zero" "0" "$rc"

# ---- Skip: actual memory acquisition (requires AVML/LiME + root) -----------
test_section "Actual acquisition and analysis (skipped)"

skip_test "acquire live memory" "requires AVML or LiME and root privileges"
skip_test "analyze memory image with volatility3" "requires volatility3 installation"

test_finish
