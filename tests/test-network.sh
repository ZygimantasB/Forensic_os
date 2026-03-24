#!/usr/bin/env bash
# =============================================================================
# test-network.sh - Tests for forensic-network tool
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

NETWORK_TOOL="$SCRIPT_DIR/../tools/forensic-network"

test_start "forensic-network tests"

# ---- Test: tool is executable ------------------------------------------------
test_section "Tool accessibility"
assert_executable "forensic-network is executable" "$NETWORK_TOOL"

# ---- Test: help/usage output ------------------------------------------------
test_section "Help and usage output"

output=$("$NETWORK_TOOL" -h 2>&1) || true
assert_contains "help shows Usage header" "Usage" "$output"
assert_contains "help mentions capture command" "capture" "$output"
assert_contains "help mentions analyze command" "analyze" "$output"

# ---- Test: missing subcommand error -----------------------------------------
test_section "Missing subcommand"

output=$("$NETWORK_TOOL" 2>&1); rc=$?; true
assert_contains "no args shows usage" "Usage" "$output"
assert_neq "no args exits non-zero" "0" "$rc"

# ---- Test: invalid subcommand error -----------------------------------------
test_section "Invalid subcommand"

output=$("$NETWORK_TOOL" invalidcmd 2>&1); rc=$?; true
assert_contains "invalid subcommand shows error" "Unknown command" "$output"
assert_neq "invalid subcommand exits non-zero" "0" "$rc"

# ---- Test: capture missing interface error ----------------------------------
test_section "Capture missing interface"

output=$("$NETWORK_TOOL" capture -o "$TEST_TMPDIR/out.pcap" 2>&1); rc=$?; true
assert_contains "capture without -i shows interface error" "Interface" "$output"
assert_neq "capture without -i exits non-zero" "0" "$rc"

# ---- Test: analyze missing input file error ---------------------------------
test_section "Analyze missing input file"

output=$("$NETWORK_TOOL" analyze 2>&1); rc=$?; true
assert_contains "analyze without -i shows input error" "Input" "$output"
assert_neq "analyze without -i exits non-zero" "0" "$rc"

# ---- Test: analyze nonexistent input file -----------------------------------
test_section "Analyze nonexistent input file"

output=$("$NETWORK_TOOL" analyze -i /nonexistent/traffic.pcap 2>&1); rc=$?; true
assert_contains "analyze nonexistent file shows error" "not found" "$output"
assert_neq "analyze nonexistent file exits non-zero" "0" "$rc"

# ---- Skip: actual capture (requires tcpdump + root) -------------------------
test_section "Actual capture and analysis (skipped)"

skip_test "capture network traffic" "requires tcpdump and root privileges"

if ! require_tool tshark; then
    skip_test "analyze PCAP file" "tshark is not installed"
else
    skip_test "analyze PCAP file" "no test PCAP fixture available"
fi

test_finish
