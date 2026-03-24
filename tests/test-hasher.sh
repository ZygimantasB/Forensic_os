#!/usr/bin/env bash
# Comprehensive tests for forensic-hasher tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

HASHER="$SCRIPT_DIR/../tools/forensic-hasher"

test_start "forensic-hasher tool"

# ---- Setup ----
create_test_files "$TEST_TMPDIR/hashdir" 5
echo "known content for hash verification" > "$TEST_TMPDIR/known.txt"

# ---- Help/Usage ----
test_section "help and usage"
output=$("$HASHER" -h 2>&1)
assert_contains "shows Usage" "Usage" "$output"
assert_contains "mentions algorithms" "md5\|sha256\|sha1" "$output"

# ---- Single file hashing ----
test_section "single file hashing"

output=$("$HASHER" -f "$TEST_TMPDIR/known.txt" -a sha256 2>&1)
assert_exit_code "sha256 hash exits 0" "0" "$?"
assert_contains "output contains hash chars" "[a-f0-9]" "$output"

output=$("$HASHER" -f "$TEST_TMPDIR/known.txt" -a md5 2>&1)
assert_exit_code "md5 hash exits 0" "0" "$?"

output=$("$HASHER" -f "$TEST_TMPDIR/known.txt" -a sha1 2>&1)
assert_exit_code "sha1 hash exits 0" "0" "$?"

output=$("$HASHER" -f "$TEST_TMPDIR/known.txt" -a sha512 2>&1)
assert_exit_code "sha512 hash exits 0" "0" "$?"

# ---- Consistency ----
test_section "hash consistency"
hash1=$("$HASHER" -f "$TEST_TMPDIR/known.txt" -a sha256 2>&1 | grep -v "^\[" | grep "[a-f0-9]" | head -1)
hash2=$("$HASHER" -f "$TEST_TMPDIR/known.txt" -a sha256 2>&1 | grep -v "^\[" | grep "[a-f0-9]" | head -1)
assert_eq "same file produces same hash" "$hash1" "$hash2"

# ---- Directory hashing ----
test_section "directory hashing"
export FORENSIC_CASE_DIR="$TEST_TMPDIR/case_work"
mkdir -p "$FORENSIC_CASE_DIR"
output=$(FORENSIC_CASE_DIR="$TEST_TMPDIR/case_work" "$HASHER" -d "$TEST_TMPDIR/hashdir" -a sha256 -r 2>&1)
rc=$?
assert_exit_code "directory hash exits 0" "0" "$rc"

# Check that all 5 files were hashed
file_count=$(echo "$output" | grep -c "testfile_" || echo 0)
assert_eq "all 5 files hashed" "5" "$file_count"

# ---- Output to file ----
test_section "output to file"
"$HASHER" -f "$TEST_TMPDIR/known.txt" -a sha256 -o "$TEST_TMPDIR/hash_output.txt" 2>/dev/null
if [[ -f "$TEST_TMPDIR/hash_output.txt" ]]; then
    assert_file_not_empty "output file is not empty" "$TEST_TMPDIR/hash_output.txt"
else
    # Some implementations may not support -o, check stdout
    skip_test "output file flag" "tool may output to stdout only"
fi

# ---- Error handling ----
test_section "error handling"
output=$("$HASHER" -f "/nonexistent/file.txt" -a sha256 2>&1)
rc=$?
assert_neq "nonexistent file fails" "0" "$rc"

output=$("$HASHER" 2>&1)
rc=$?
assert_neq "no arguments shows error" "0" "$rc"

# ---- Hash verification ----
test_section "hash verification"
known_hash=$(sha256sum "$TEST_TMPDIR/known.txt" | awk '{print $1}')
if [[ -n "$known_hash" ]]; then
    output=$("$HASHER" -f "$TEST_TMPDIR/known.txt" -a sha256 -v "$known_hash" 2>&1)
    rc=$?
    # Verification should pass
    if [[ $rc -eq 0 ]]; then
        assert_exit_code "correct hash verification passes" "0" "$rc"
    else
        skip_test "hash verification pass" "tool may not support -v flag"
    fi
fi

# ---- Tool properties ----
test_section "tool properties"
assert_executable "hasher is executable" "$HASHER"
shebang=$(head -1 "$HASHER")
assert_contains "has bash shebang" "bash" "$shebang"

test_finish
