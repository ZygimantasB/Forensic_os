#!/usr/bin/env bash
# Tests for forensic-imager tool (non-destructive tests only)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGER="$SCRIPT_DIR/../tools/forensic-imager"

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

echo "=== Testing forensic-imager ==="

# Test help
echo "-- help output --"
output=$("$IMAGER" -h 2>&1)
assert_contains "shows usage" "Usage" "$output"

# Test missing arguments
echo "-- missing arguments --"
output=$("$IMAGER" 2>&1)
assert_contains "shows error for missing args" "source\|Usage\|error" "$output"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
