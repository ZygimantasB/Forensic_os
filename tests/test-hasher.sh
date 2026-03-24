#!/usr/bin/env bash
# Tests for forensic-hasher tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASHER="$SCRIPT_DIR/../tools/forensic-hasher"

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

assert_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -q "$needle"; then
        echo "  PASS: $desc"
        ((PASS++))
    else
        echo "  FAIL: $desc (output does not contain '$needle')"
        ((FAIL++))
    fi
}

echo "=== Testing forensic-hasher ==="

# Create test file
TMPDIR=$(mktemp -d)
echo "test forensic data 12345" > "$TMPDIR/testfile.txt"

# Test help
echo "-- help output --"
output=$("$HASHER" -h 2>&1)
assert_contains "shows usage" "Usage" "$output"

# Test single file hash
echo "-- single file hashing --"
output=$("$HASHER" -f "$TMPDIR/testfile.txt" -a sha256 2>&1)
assert_eq "exits successfully" "0" "$?"

# Test MD5
output=$("$HASHER" -f "$TMPDIR/testfile.txt" -a md5 2>&1)
assert_eq "md5 exits successfully" "0" "$?"

# Test directory hashing
echo "-- directory hashing --"
echo "another file" > "$TMPDIR/file2.txt"
output=$("$HASHER" -d "$TMPDIR" -a sha256 -r 2>&1)
assert_eq "directory hash exits successfully" "0" "$?"

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
