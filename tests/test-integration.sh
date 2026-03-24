#!/usr/bin/env bash
# =============================================================================
# test-integration.sh - End-to-end integration tests for ForensicOS
# =============================================================================
# Tests the full case workflow: init -> evidence -> hash -> report -> close

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

TOOLS_DIR="$SCRIPT_DIR/../tools"
CASE_TOOL="$TOOLS_DIR/forensic-case"
HASHER_TOOL="$TOOLS_DIR/forensic-hasher"
REPORT_TOOL="$TOOLS_DIR/forensic-report"

test_start "integration tests"

# Override environment so tools use our temp directories
export FORENSIC_CASES_DIR="$TEST_TMPDIR/cases"
export TEMPLATE_DIR="$SCRIPT_DIR/../templates"
mkdir -p "$FORENSIC_CASES_DIR"

CASE_NUMBER="TEST-001"
EXAMINER="Test Examiner"
DESCRIPTION="Integration test"

# =============================================================================
# Step 1: Initialize a case
# =============================================================================
test_section "Step 1: Initialize a case"

output=$("$CASE_TOOL" init -n "$CASE_NUMBER" -e "$EXAMINER" -d "$DESCRIPTION" 2>&1)
rc=$?
assert_exit_code "case init exits successfully" "0" "$rc"
assert_contains "case init shows case number" "$CASE_NUMBER" "$output"

CASE_DIR="$FORENSIC_CASES_DIR/$CASE_NUMBER"

# =============================================================================
# Step 2: Verify case directory structure
# =============================================================================
test_section "Step 2: Verify case directory structure"

assert_dir_exists "case directory exists" "$CASE_DIR"
assert_dir_exists "evidence directory exists" "$CASE_DIR/evidence"
assert_dir_exists "reports directory exists" "$CASE_DIR/reports"
assert_dir_exists "notes directory exists" "$CASE_DIR/notes"
assert_dir_exists "logs directory exists" "$CASE_DIR/logs"
assert_file_exists "case.json exists" "$CASE_DIR/case.json"
assert_file_exists "chain-of-custody.jsonl exists" "$CASE_DIR/logs/chain-of-custody.jsonl"

# Verify case.json contents
case_status=$(python3 -c "import json; print(json.load(open('$CASE_DIR/case.json'))['status'])" 2>/dev/null)
assert_eq "case status is open" "open" "$case_status"

case_num_from_json=$(python3 -c "import json; print(json.load(open('$CASE_DIR/case.json'))['case_number'])" 2>/dev/null)
assert_eq "case number matches" "$CASE_NUMBER" "$case_num_from_json"

examiner_from_json=$(python3 -c "import json; print(json.load(open('$CASE_DIR/case.json'))['examiner'])" 2>/dev/null)
assert_eq "examiner matches" "$EXAMINER" "$examiner_from_json"

# =============================================================================
# Step 3: Create test evidence files
# =============================================================================
test_section "Step 3: Create test evidence files"

EVIDENCE_DIR="$CASE_DIR/evidence"
create_test_file "$EVIDENCE_DIR/document.txt" "This is a confidential document found on the suspect drive."
create_test_file "$EVIDENCE_DIR/log_extract.txt" "2026-03-24 08:00:00 Login attempt from 192.168.1.100"
create_test_file "$EVIDENCE_DIR/recovered_email.eml" "From: suspect@example.com\nTo: accomplice@example.com\nSubject: Meeting\n\nMeet at the usual place."

assert_file_exists "document.txt exists" "$EVIDENCE_DIR/document.txt"
assert_file_exists "log_extract.txt exists" "$EVIDENCE_DIR/log_extract.txt"
assert_file_exists "recovered_email.eml exists" "$EVIDENCE_DIR/recovered_email.eml"

# =============================================================================
# Step 4: Run forensic-hasher on evidence files
# =============================================================================
test_section "Step 4: Hash evidence files"

# Hash each evidence file individually to collect results
HASH_RESULTS="$TEST_TMPDIR/evidence_hashes.txt"
: > "$HASH_RESULTS"

for efile in "$EVIDENCE_DIR"/*; do
    [[ -f "$efile" ]] || continue
    "$HASHER_TOOL" -f "$efile" -a sha256 >> "$HASH_RESULTS" 2>&1
done
rc=$?
assert_exit_code "hasher exits successfully" "0" "$rc"
assert_file_exists "hash output file exists" "$HASH_RESULTS"

# =============================================================================
# Step 5: Verify hashes are computed correctly
# =============================================================================
test_section "Step 5: Verify hash correctness"

assert_file_not_empty "hash output is not empty" "$HASH_RESULTS"

# Verify we can independently reproduce one hash
expected_hash=$(sha256sum "$EVIDENCE_DIR/document.txt" | awk '{print $1}')
assert_file_contains "hash file contains document.txt hash" "$expected_hash" "$HASH_RESULTS"

# Check the hashdeep header is present
assert_file_contains "hash file has hashdeep header" "HASHDEEP" "$HASH_RESULTS"

# =============================================================================
# Step 6: Run forensic-report summary on the case
# =============================================================================
test_section "Step 6: Case summary report"

summary_output=$("$REPORT_TOOL" summary -c "$CASE_DIR" 2>&1)
rc=$?
assert_exit_code "report summary exits successfully" "0" "$rc"
assert_contains "summary contains case number" "$CASE_NUMBER" "$summary_output"
assert_contains "summary contains examiner" "$EXAMINER" "$summary_output"
assert_contains "summary shows OPEN status" "OPEN" "$summary_output"

# =============================================================================
# Step 7: Generate HTML report
# =============================================================================
test_section "Step 7: Generate HTML report"

REPORT_FILE="$CASE_DIR/reports/forensic-report-${CASE_NUMBER}.html"

report_output=$("$REPORT_TOOL" generate -c "$CASE_DIR" -f html 2>&1)
rc=$?
assert_exit_code "report generate exits successfully" "0" "$rc"

# =============================================================================
# Step 8: Verify report file
# =============================================================================
test_section "Step 8: Verify report contents"

assert_file_exists "HTML report file exists" "$REPORT_FILE"
assert_file_not_empty "HTML report is not empty" "$REPORT_FILE"
assert_file_contains "report contains case number" "$CASE_NUMBER" "$REPORT_FILE"

# =============================================================================
# Step 9: Close the case
# =============================================================================
test_section "Step 9: Close the case"

close_output=$("$CASE_TOOL" close 2>&1)
rc=$?
assert_exit_code "case close exits successfully" "0" "$rc"
assert_contains "close output confirms closure" "closed" "$close_output"

# =============================================================================
# Step 10: Verify case is closed
# =============================================================================
test_section "Step 10: Verify case is closed"

closed_status=$(python3 -c "import json; print(json.load(open('$CASE_DIR/case.json'))['status'])" 2>/dev/null)
assert_eq "case status is closed" "closed" "$closed_status"

closed_date=$(python3 -c "import json; print(json.load(open('$CASE_DIR/case.json')).get('closed', ''))" 2>/dev/null)
assert_not_empty "closed date is set" "$closed_date"

# =============================================================================
# Step 11: Verify integrity-verification.log was created
# =============================================================================
test_section "Step 11: Verify integrity verification log"

INTEGRITY_LOG="$CASE_DIR/logs/integrity-verification.log"
assert_file_exists "integrity-verification.log exists" "$INTEGRITY_LOG"
assert_file_not_empty "integrity-verification.log is not empty" "$INTEGRITY_LOG"
assert_file_contains "integrity log contains SHA256 hashes" "SHA256" "$INTEGRITY_LOG"
assert_file_contains "integrity log contains document.txt" "document.txt" "$INTEGRITY_LOG"

test_finish
