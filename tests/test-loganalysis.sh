#!/usr/bin/env bash
# =============================================================================
# test-loganalysis.sh - Tests for forensic-loganalysis tool
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

TOOL="$SCRIPT_DIR/../tools/forensic-loganalysis"

test_start "forensic-loganalysis tests"

# =============================================================================
test_section "Help and usage output"
# =============================================================================

output=$("$TOOL" -h 2>&1 || true)
assert_contains "Help flag shows usage" "Usage" "$output"
assert_contains "Help mentions source option" "-s SOURCE" "$output"
assert_contains "Help mentions keyword option" "-k KEYWORD" "$output"
assert_contains "Help mentions output option" "-o OUTPUT" "$output"
assert_contains "Help mentions format option" "-f FORMAT" "$output"
assert_contains "Help mentions type option" "-t TYPE" "$output"

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

output=$("$TOOL" -s /nonexistent/logdir 2>&1 || true)
rc=0; "$TOOL" -s /nonexistent/logdir >/dev/null 2>&1 || rc=$?
assert_exit_code "Nonexistent source exits non-zero" "1" "$rc"
assert_contains "Nonexistent source reports error" "does not exist" "$output"

# =============================================================================
test_section "Syslog fixture - auto-detection"
# =============================================================================

log_dir="$TEST_TMPDIR/logs"
mkdir -p "$log_dir"
create_syslog_fixture "$log_dir/syslog"

output=$("$TOOL" -s "$log_dir" -t auto 2>&1 || true)
assert_contains "Auto-detection finds syslog" "Found" "$output"
assert_contains "Auto-detection reports analysis" "analysis\|complete\|analyzed" "$output"

# =============================================================================
test_section "Syslog fixture - keyword search"
# =============================================================================

output=$("$TOOL" -s "$log_dir" -k "Failed" 2>&1 || true)
assert_contains "Keyword search finds Failed" "Failed" "$output"
assert_contains "Keyword search reports matches" "matching" "$output"

# =============================================================================
test_section "Syslog fixture - CSV format"
# =============================================================================

output=$("$TOOL" -s "$log_dir" -k "Failed" -f csv 2>&1 || true)
assert_contains "CSV output has header" "file,line_number,content" "$output"
assert_contains "CSV output has match data" "Failed" "$output"

# =============================================================================
test_section "Auth log fixture - keyword search"
# =============================================================================

auth_dir="$TEST_TMPDIR/authlogs"
mkdir -p "$auth_dir"
create_authlog_fixture "$auth_dir/auth.log"

output=$("$TOOL" -s "$auth_dir" -k "Failed" 2>&1 || true)
assert_contains "Auth log keyword search finds Failed" "Failed" "$output"
assert_contains "Auth log keyword search reports matches" "matching" "$output"

# =============================================================================
test_section "Apache log fixture - analysis"
# =============================================================================

apache_dir="$TEST_TMPDIR/apachelogs"
mkdir -p "$apache_dir"
create_apache_fixture "$apache_dir/access.log"

output=$("$TOOL" -s "$apache_dir" -t apache 2>&1 || true)
assert_contains "Apache analysis finds log files" "Found" "$output"
assert_contains "Apache analysis completes" "analysis\|complete\|analyzed" "$output"

# =============================================================================
test_section "Suspicious pattern detection"
# =============================================================================

output=$("$TOOL" -s "$apache_dir" -t apache 2>&1 || true)
assert_contains "Suspicious pattern detection mentions SQL injection" "suspicious\|Suspicious\|UNION\|SQL\|injection\|Top IPs" "$output"

# =============================================================================
test_section "Output to file (-o flag)"
# =============================================================================

outfile="$TEST_TMPDIR/report_output.txt"
output=$("$TOOL" -s "$log_dir" -k "CRON" -o "$outfile" 2>&1 || true)
assert_file_exists "Output file is created" "$outfile"
assert_file_not_empty "Output file is not empty" "$outfile"
assert_file_contains "Output file contains match" "CRON" "$outfile"

# =============================================================================
test_section "Executable check"
# =============================================================================

assert_executable "forensic-loganalysis is executable" "$TOOL"

test_finish
