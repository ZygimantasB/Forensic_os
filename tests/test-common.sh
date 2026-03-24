#!/usr/bin/env bash
# Tests for forensic-common.sh library

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/forensic-common.sh" 2>/dev/null || {
    echo "FAIL: Could not source forensic-common.sh"
    exit 1
}

PASS=0
FAIL=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $desc"
        ((PASS++))
    else
        echo "  FAIL: $desc (expected='$expected', got='$actual')"
        ((FAIL++))
    fi
}

assert_not_empty() {
    local desc="$1" value="$2"
    if [[ -n "$value" ]]; then
        echo "  PASS: $desc"
        ((PASS++))
    else
        echo "  FAIL: $desc (value is empty)"
        ((FAIL++))
    fi
}

echo "=== Testing forensic-common.sh ==="

# Test timestamp
echo "-- timestamp function --"
ts=$(timestamp)
assert_not_empty "timestamp returns a value" "$ts"

# Test format_size
echo "-- format_size function --"
assert_eq "0 bytes" "0 B" "$(format_size 0)"
assert_eq "1023 bytes" "1023 B" "$(format_size 1023)"
result_kb=$(format_size 1024)
assert_eq "1 KB/KiB" "1" "$(echo "$result_kb" | grep -c '1.0')"
result_mb=$(format_size 1048576)
assert_eq "1 MB/MiB" "1" "$(echo "$result_mb" | grep -c '1.0')"
result_gb=$(format_size 1073741824)
assert_eq "1 GB/GiB" "1" "$(echo "$result_gb" | grep -c '1.0\|GiB')"

# Test generate_hash
echo "-- generate_hash function --"
TMPFILE=$(mktemp)
echo "forensic test data" > "$TMPFILE"
hash_sha256=$(generate_hash "$TMPFILE" sha256)
assert_not_empty "SHA256 hash generated" "$hash_sha256"
hash_md5=$(generate_hash "$TMPFILE" md5)
assert_not_empty "MD5 hash generated" "$hash_md5"

# Test verify_hash
echo "-- verify_hash function --"
verify_hash "$TMPFILE" "$hash_sha256" sha256
assert_eq "SHA256 verification passes" "0" "$?"
verify_hash "$TMPFILE" "badhash" sha256
assert_eq "Bad hash verification fails" "1" "$?"

rm -f "$TMPFILE"

# Test check_tool
echo "-- check_tool function --"
check_tool "bash" >/dev/null 2>&1
assert_eq "bash is available" "0" "$?"
check_tool "nonexistent_tool_xyz" >/dev/null 2>&1
assert_eq "nonexistent tool is not available" "1" "$?"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
