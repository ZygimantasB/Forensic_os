#!/usr/bin/env bash
# Tests for forensic-common.sh library

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"
source "$SCRIPT_DIR/../lib/forensic-common.sh" 2>/dev/null || {
    echo "FAIL: Could not source forensic-common.sh"
    exit 1
}

test_start "forensic-common.sh library"

# ---- Timestamp ----
test_section "timestamp function"
ts=$(timestamp)
assert_not_empty "timestamp returns a value" "$ts"
assert_contains "timestamp has date format" "T" "$ts"

# ---- format_size ----
test_section "format_size function"
assert_eq "0 bytes" "0 B" "$(format_size 0)"
assert_eq "512 bytes" "512 B" "$(format_size 512)"
assert_eq "1023 bytes" "1023 B" "$(format_size 1023)"
result_kb=$(format_size 1024)
assert_contains "1024 bytes shows K" "1.0" "$result_kb"
result_mb=$(format_size 1048576)
assert_contains "1MB shows M" "1.0" "$result_mb"
result_gb=$(format_size 1073741824)
assert_contains "1GB shows G" "1.0" "$result_gb"

# ---- generate_hash ----
test_section "generate_hash function"
TMPFILE="$TEST_TMPDIR/hashtest.txt"
echo "forensic test data" > "$TMPFILE"

hash_sha256=$(generate_hash "$TMPFILE" sha256)
assert_not_empty "SHA256 hash generated" "$hash_sha256"
assert_eq "SHA256 hash length is 64" "64" "${#hash_sha256}"

hash_md5=$(generate_hash "$TMPFILE" md5)
assert_not_empty "MD5 hash generated" "$hash_md5"
assert_eq "MD5 hash length is 32" "32" "${#hash_md5}"

hash_sha1=$(generate_hash "$TMPFILE" sha1)
assert_not_empty "SHA1 hash generated" "$hash_sha1"
assert_eq "SHA1 hash length is 40" "40" "${#hash_sha1}"

hash_sha512=$(generate_hash "$TMPFILE" sha512)
assert_not_empty "SHA512 hash generated" "$hash_sha512"
assert_eq "SHA512 hash length is 128" "128" "${#hash_sha512}"

# Test unsupported algorithm
output=$(generate_hash "$TMPFILE" blake2 2>&1)
assert_exit_code "unsupported algorithm fails" "1" "$?"

# Test missing file
output=$(generate_hash "/nonexistent/file" sha256 2>&1)
assert_exit_code "missing file fails" "1" "$?"

# ---- verify_hash ----
test_section "verify_hash function"
verify_hash "$TMPFILE" "$hash_sha256" sha256 2>/dev/null
assert_exit_code "correct hash verifies" "0" "$?"

verify_hash "$TMPFILE" "badhash123" sha256 2>/dev/null
assert_exit_code "wrong hash fails verification" "1" "$?"

# Same content = same hash
TMPFILE2="$TEST_TMPDIR/hashtest2.txt"
echo "forensic test data" > "$TMPFILE2"
hash2=$(generate_hash "$TMPFILE2" sha256)
assert_eq "identical content produces identical hash" "$hash_sha256" "$hash2"

# Different content = different hash
echo "different data" > "$TMPFILE2"
hash3=$(generate_hash "$TMPFILE2" sha256)
assert_neq "different content produces different hash" "$hash_sha256" "$hash3"

# ---- check_tool ----
test_section "check_tool function"
check_tool "bash" >/dev/null 2>&1
assert_exit_code "bash is available" "0" "$?"

check_tool "nonexistent_tool_xyz_123" >/dev/null 2>&1
assert_exit_code "nonexistent tool is not available" "1" "$?"

check_tool "sha256sum" >/dev/null 2>&1
assert_exit_code "sha256sum is available" "0" "$?"

# ---- get_case_dir ----
test_section "get_case_dir function"
export FORENSIC_CASE_DIR="$TEST_TMPDIR/test_case_dir"
case_dir=$(get_case_dir)
assert_eq "get_case_dir returns expected path" "$TEST_TMPDIR/test_case_dir" "$case_dir"
assert_dir_exists "get_case_dir creates directory" "$TEST_TMPDIR/test_case_dir"

# ---- audit_log ----
test_section "audit_log function"
export FORENSIC_CASE_DIR="$TEST_TMPDIR/audit_test"
mkdir -p "$FORENSIC_CASE_DIR"
FORENSIC_TOOL_NAME="test-tool" audit_log "test action performed" 2>/dev/null
assert_file_exists "audit log file created" "$FORENSIC_CASE_DIR/audit.log"
assert_file_contains "audit log has action" "test action performed" "$FORENSIC_CASE_DIR/audit.log"
assert_file_contains "audit log has tool name" "test-tool" "$FORENSIC_CASE_DIR/audit.log"

# ---- Color constants ----
test_section "color constants"
assert_not_empty "NC is defined" "${NC+x}"
assert_not_empty "BOLD is defined" "${BOLD+x}"

# ---- Double-sourcing prevention ----
test_section "double-sourcing prevention"
assert_eq "guard variable is set" "1" "$_FORENSIC_COMMON_LOADED"

test_finish
