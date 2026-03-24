#!/usr/bin/env bash
# =============================================================================
# test-framework.sh - Shared testing framework for ForensicOS
# =============================================================================
# Source this file from all test scripts to get assertion functions,
# test setup/teardown helpers, and result reporting.
# =============================================================================

# Prevent double-sourcing
[[ -n "${_TEST_FRAMEWORK_LOADED:-}" ]] && return 0
_TEST_FRAMEWORK_LOADED=1

# ---- Test State -------------------------------------------------------------
TEST_PASS=0
TEST_FAIL=0
TEST_SKIP=0
TEST_NAME=""
TEST_TMPDIR=""

# ---- Colors (always on for tests) ------------------------------------------
_T_RED='\033[0;31m'
_T_GREEN='\033[0;32m'
_T_YELLOW='\033[1;33m'
_T_BLUE='\033[0;34m'
_T_BOLD='\033[1m'
_T_NC='\033[0m'

# ---- Test Lifecycle ---------------------------------------------------------

# Call at the start of a test file
test_start() {
    TEST_NAME="${1:-$(basename "$0")}"
    echo -e "${_T_BOLD}=== ${TEST_NAME} ===${_T_NC}"
    TEST_TMPDIR="$(mktemp -d /tmp/forensic-test-XXXXXX)"
    export FORENSIC_CASES_DIR="$TEST_TMPDIR/cases"
    export FORENSIC_CASE_DIR="$TEST_TMPDIR/case_work"
    export FORENSIC_LOG_FILE="$TEST_TMPDIR/test.log"
    mkdir -p "$FORENSIC_CASES_DIR" "$FORENSIC_CASE_DIR"
}

# Call at the end of a test file
test_finish() {
    echo ""
    local total=$((TEST_PASS + TEST_FAIL + TEST_SKIP))
    echo -e "${_T_BOLD}--- Results: ${_T_GREEN}${TEST_PASS} passed${_T_NC}, ${_T_RED}${TEST_FAIL} failed${_T_NC}, ${_T_YELLOW}${TEST_SKIP} skipped${_T_NC} (${total} total) ---${_T_NC}"

    # Clean up temp directory
    if [[ -n "$TEST_TMPDIR" && -d "$TEST_TMPDIR" ]]; then
        rm -rf "$TEST_TMPDIR"
    fi

    exit "$TEST_FAIL"
}

# Print a section header
test_section() {
    echo -e "\n${_T_BLUE}-- $1 --${_T_NC}"
}

# ---- Assertion Functions ----------------------------------------------------

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (expected='$expected', got='$actual')"
        ((TEST_FAIL++))
    fi
}

assert_neq() {
    local desc="$1" not_expected="$2" actual="$3"
    if [[ "$not_expected" != "$actual" ]]; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (should not equal '$not_expected')"
        ((TEST_FAIL++))
    fi
}

assert_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -qi -- "$needle"; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (output does not contain '$needle')"
        ((TEST_FAIL++))
    fi
}

assert_not_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if ! echo "$haystack" | grep -qi -- "$needle"; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (output should not contain '$needle')"
        ((TEST_FAIL++))
    fi
}

assert_not_empty() {
    local desc="$1" value="$2"
    if [[ -n "$value" ]]; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (value is empty)"
        ((TEST_FAIL++))
    fi
}

assert_empty() {
    local desc="$1" value="$2"
    if [[ -z "$value" ]]; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (value should be empty, got '$value')"
        ((TEST_FAIL++))
    fi
}

assert_file_exists() {
    local desc="$1" path="$2"
    if [[ -f "$path" ]]; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (file not found: $path)"
        ((TEST_FAIL++))
    fi
}

assert_dir_exists() {
    local desc="$1" path="$2"
    if [[ -d "$path" ]]; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (directory not found: $path)"
        ((TEST_FAIL++))
    fi
}

assert_file_not_empty() {
    local desc="$1" path="$2"
    if [[ -f "$path" && -s "$path" ]]; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (file empty or missing: $path)"
        ((TEST_FAIL++))
    fi
}

assert_exit_code() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc (exit code $actual)"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (expected exit $expected, got $actual)"
        ((TEST_FAIL++))
    fi
}

assert_executable() {
    local desc="$1" path="$2"
    if [[ -x "$path" ]]; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc (not executable: $path)"
        ((TEST_FAIL++))
    fi
}

assert_file_contains() {
    local desc="$1" needle="$2" filepath="$3"
    if grep -q -- "$needle" "$filepath" 2>/dev/null; then
        echo -e "  ${_T_GREEN}PASS${_T_NC}: $desc"
        ((TEST_PASS++))
    else
        echo -e "  ${_T_RED}FAIL${_T_NC}: $desc ('$needle' not found in $filepath)"
        ((TEST_FAIL++))
    fi
}

# Skip a test with a reason
skip_test() {
    local desc="$1" reason="$2"
    echo -e "  ${_T_YELLOW}SKIP${_T_NC}: $desc ($reason)"
    ((TEST_SKIP++))
}

# Check if a command is available; if not, skip
require_tool() {
    local tool="$1"
    if ! command -v "$tool" &>/dev/null; then
        return 1
    fi
    return 0
}

# ---- Helper Functions -------------------------------------------------------

# Create a small test disk image (raw, 1MB with ext4)
create_test_image() {
    local path="$1"
    local size_mb="${2:-1}"
    dd if=/dev/zero of="$path" bs=1M count="$size_mb" 2>/dev/null
}

# Create a test file with known content
create_test_file() {
    local path="$1"
    local content="${2:-This is test forensic data created at $(date)}"
    echo "$content" > "$path"
}

# Create multiple test files in a directory
create_test_files() {
    local dir="$1"
    local count="${2:-5}"
    mkdir -p "$dir"
    for i in $(seq 1 "$count"); do
        echo "Test file $i content - $(date +%s%N)" > "$dir/testfile_${i}.txt"
    done
}

# Create a fake log file (syslog format)
create_syslog_fixture() {
    local path="$1"
    cat > "$path" << 'SYSLOG'
Mar 24 08:00:01 forensic-ws CRON[1234]: (root) CMD (/usr/bin/backup)
Mar 24 08:01:15 forensic-ws sshd[5678]: Failed password for invalid user admin from 192.168.1.100 port 54321 ssh2
Mar 24 08:01:16 forensic-ws sshd[5678]: Failed password for invalid user root from 192.168.1.100 port 54322 ssh2
Mar 24 08:02:30 forensic-ws sshd[5680]: Accepted publickey for analyst from 10.0.0.5 port 44100 ssh2
Mar 24 08:05:00 forensic-ws kernel: [UFW BLOCK] IN=eth0 OUT= SRC=192.168.1.100 DST=10.0.0.1
Mar 24 08:10:00 forensic-ws sudo: analyst : TTY=pts/0 ; PWD=/home/analyst ; USER=root ; COMMAND=/bin/mount
Mar 24 08:15:22 forensic-ws kernel: error reading sector 1024 from sdb
Mar 24 08:20:00 forensic-ws systemd[1]: Started Forensic Audit Service.
Mar 24 09:00:00 forensic-ws CRON[2345]: (root) CMD (/usr/bin/check_evidence)
Mar 24 09:30:45 forensic-ws sshd[6789]: Failed password for user test from 10.10.10.10 port 22 ssh2
SYSLOG
}

# Create a fake auth log
create_authlog_fixture() {
    local path="$1"
    cat > "$path" << 'AUTHLOG'
Mar 24 08:01:15 forensic-ws sshd[5678]: Failed password for invalid user admin from 192.168.1.100 port 54321 ssh2
Mar 24 08:01:16 forensic-ws sshd[5678]: Failed password for invalid user root from 192.168.1.100 port 54322 ssh2
Mar 24 08:02:30 forensic-ws sshd[5680]: Accepted publickey for analyst from 10.0.0.5 port 44100 ssh2
Mar 24 08:10:00 forensic-ws sudo: analyst : TTY=pts/0 ; PWD=/home/analyst ; USER=root ; COMMAND=/bin/mount
Mar 24 09:30:45 forensic-ws sshd[6789]: Failed password for user test from 10.10.10.10 port 22 ssh2
Mar 24 10:00:00 forensic-ws useradd[9999]: new user: name=forensic, UID=1001, GID=1001
AUTHLOG
}

# Create a fake Apache access log
create_apache_fixture() {
    local path="$1"
    cat > "$path" << 'APACHE'
192.168.1.50 - - [24/Mar/2026:08:00:01 +0000] "GET / HTTP/1.1" 200 1234
192.168.1.50 - - [24/Mar/2026:08:00:02 +0000] "GET /login HTTP/1.1" 200 5678
192.168.1.100 - - [24/Mar/2026:08:01:00 +0000] "POST /login HTTP/1.1" 401 123
192.168.1.100 - - [24/Mar/2026:08:01:05 +0000] "GET /admin' UNION SELECT * FROM users-- HTTP/1.1" 400 0
192.168.1.100 - - [24/Mar/2026:08:01:10 +0000] "GET /../../etc/passwd HTTP/1.1" 403 0
10.0.0.5 - analyst [24/Mar/2026:08:05:00 +0000] "GET /dashboard HTTP/1.1" 200 9876
10.0.0.5 - analyst [24/Mar/2026:08:10:00 +0000] "GET /evidence/list HTTP/1.1" 200 4567
APACHE
}
