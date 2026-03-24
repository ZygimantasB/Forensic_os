#!/usr/bin/env bash
# Tests for forensic-case tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

CASE_TOOL="$SCRIPT_DIR/../tools/forensic-case"

test_start "forensic-case tests"

# ---- Sanity checks -----------------------------------------------------------
test_section "Sanity checks"

assert_file_exists "forensic-case tool exists" "$CASE_TOOL"
assert_executable "forensic-case is executable" "$CASE_TOOL"

shebang=$(head -1 "$CASE_TOOL")
assert_contains "has proper shebang" "#!/usr/bin/env bash" "$shebang"

# ---- Help / usage output -----------------------------------------------------
test_section "Help / usage output"

help_output=$("$CASE_TOOL" --help 2>&1 || true)
assert_contains "help shows Usage" "Usage" "$help_output"
assert_contains "help mentions init" "init" "$help_output"
assert_contains "help mentions status" "status" "$help_output"
assert_contains "help mentions list" "list" "$help_output"
assert_contains "help mentions close" "close" "$help_output"

no_args_output=$("$CASE_TOOL" 2>&1 || true)
assert_contains "no args shows usage" "Usage" "$no_args_output"

# ---- Case init with all flags ------------------------------------------------
test_section "Case init with all flags"

export FORENSIC_CASES_DIR="$TEST_TMPDIR/cases"
mkdir -p "$FORENSIC_CASES_DIR"

CASE_NUM="2026-0099"
EXAMINER="Test Analyst"
DESCRIPTION="Test case for unit tests"

init_output=$("$CASE_TOOL" init -n "$CASE_NUM" -e "$EXAMINER" -d "$DESCRIPTION" 2>&1)
init_rc=$?

assert_exit_code "init exits successfully" "0" "$init_rc"
assert_contains "init output shows case number" "$CASE_NUM" "$init_output"
assert_contains "init output shows examiner" "$EXAMINER" "$init_output"

CASE_DIR="$FORENSIC_CASES_DIR/$CASE_NUM"

assert_dir_exists "case directory created" "$CASE_DIR"
assert_dir_exists "evidence subdir created" "$CASE_DIR/evidence"
assert_dir_exists "reports subdir created" "$CASE_DIR/reports"
assert_dir_exists "notes subdir created" "$CASE_DIR/notes"
assert_dir_exists "logs subdir created" "$CASE_DIR/logs"

assert_file_exists "case.json created" "$CASE_DIR/case.json"
assert_file_not_empty "case.json is not empty" "$CASE_DIR/case.json"

COC_FILE="$CASE_DIR/logs/chain-of-custody.jsonl"
assert_file_exists "chain-of-custody.jsonl created" "$COC_FILE"
assert_file_not_empty "chain-of-custody.jsonl is not empty" "$COC_FILE"

# Validate case.json is valid JSON with correct fields
json_valid=$(python3 -c "
import json, sys
with open('$CASE_DIR/case.json') as f:
    data = json.load(f)
assert data['case_number'] == '$CASE_NUM', 'case_number mismatch'
assert data['examiner'] == '$EXAMINER', 'examiner mismatch'
assert data['description'] == '$DESCRIPTION', 'description mismatch'
assert data['status'] == 'open', 'status should be open'
print('OK')
" 2>&1)
assert_eq "case.json has valid JSON with correct fields" "OK" "$json_valid"

# Validate chain-of-custody.jsonl entries are valid JSON
coc_valid=$(python3 -c "
import json, sys
with open('$COC_FILE') as f:
    for i, line in enumerate(f, 1):
        line = line.strip()
        if not line:
            continue
        json.loads(line)
print('OK')
" 2>&1)
assert_eq "chain-of-custody.jsonl entries are valid JSON" "OK" "$coc_valid"

# Validate .current_case was set
assert_file_exists ".current_case file created" "$FORENSIC_CASES_DIR/.current_case"
current_case_content=$(cat "$FORENSIC_CASES_DIR/.current_case")
assert_eq ".current_case contains case number" "$CASE_NUM" "$current_case_content"

# ---- Auto-generated case number format ---------------------------------------
test_section "Auto-generated case number format"

# Create a second case without -n to test auto-generated number
auto_output=$("$CASE_TOOL" init -e "Auto Tester" -d "Auto number test" 2>&1)
auto_rc=$?
assert_exit_code "auto-generated case init succeeds" "0" "$auto_rc"

# The auto-generated number should match YYYY-NNNN format
year=$(date +%Y)
assert_contains "auto output contains year" "$year" "$auto_output"

# Check that a directory matching the pattern was created
auto_case_found=0
for d in "$FORENSIC_CASES_DIR/${year}"-*/; do
    if [[ -d "$d" && "$d" != *"$CASE_NUM"* ]]; then
        auto_case_found=1
        auto_case_dir="$d"
        break
    fi
done
assert_eq "auto-generated case dir created with YYYY-NNNN format" "1" "$auto_case_found"

# ---- Case status shows correct info -----------------------------------------
test_section "Case status"

# Set current case back to our known case
echo "$CASE_NUM" > "$FORENSIC_CASES_DIR/.current_case"

status_output=$("$CASE_TOOL" status 2>&1)
status_rc=$?
assert_exit_code "status exits successfully" "0" "$status_rc"
assert_contains "status shows case number" "$CASE_NUM" "$status_output"
assert_contains "status shows examiner" "$EXAMINER" "$status_output"
assert_contains "status shows description" "$DESCRIPTION" "$status_output"
assert_contains "status shows OPEN status" "OPEN" "$status_output"

# ---- Case list works ---------------------------------------------------------
test_section "Case list"

list_output=$("$CASE_TOOL" list 2>&1)
list_rc=$?
assert_exit_code "list exits successfully" "0" "$list_rc"
assert_contains "list shows our case number" "$CASE_NUM" "$list_output"
assert_contains "list shows examiner" "$EXAMINER" "$list_output"

# ---- Duplicate case init fails -----------------------------------------------
test_section "Duplicate case init"

dup_rc=0
dup_output=$("$CASE_TOOL" init -n "$CASE_NUM" -e "Dup" -d "Dup" 2>&1) || dup_rc=$?
assert_eq "duplicate case init fails with non-zero exit" "1" "$dup_rc"
assert_contains "duplicate init shows error" "already exists" "$dup_output"

# ---- Case close --------------------------------------------------------------
test_section "Case close"

# Ensure current case is set
echo "$CASE_NUM" > "$FORENSIC_CASES_DIR/.current_case"

close_output=$("$CASE_TOOL" close 2>&1)
close_rc=$?
assert_exit_code "close exits successfully" "0" "$close_rc"
assert_contains "close output confirms closure" "closed" "$close_output"

# Verify status changed to closed in case.json
closed_status=$(python3 -c "import json; print(json.load(open('$CASE_DIR/case.json'))['status'])" 2>/dev/null)
assert_eq "case.json status is closed" "closed" "$closed_status"

# Verify integrity-verification.log was created
assert_file_exists "integrity-verification.log created" "$CASE_DIR/logs/integrity-verification.log"
assert_file_not_empty "integrity-verification.log is not empty" "$CASE_DIR/logs/integrity-verification.log"

# Verify .current_case was removed
if [[ ! -f "$FORENSIC_CASES_DIR/.current_case" ]]; then
    echo -e "  ${_T_GREEN}PASS${_T_NC}: .current_case removed after close"
    ((TEST_PASS++))
else
    echo -e "  ${_T_RED}FAIL${_T_NC}: .current_case should be removed after close"
    ((TEST_FAIL++))
fi

# ---- Status with no active case ---------------------------------------------
test_section "Status with no active case"

rm -f "$FORENSIC_CASES_DIR/.current_case"
no_case_status=$("$CASE_TOOL" status 2>&1)
no_case_rc=$?
assert_exit_code "status with no active case exits 0" "0" "$no_case_rc"
assert_contains "status warns about no active case" "No active case" "$no_case_status"

# ---- Close with no active case ----------------------------------------------
test_section "Close with no active case"

rm -f "$FORENSIC_CASES_DIR/.current_case"
no_case_close_rc=0
no_case_close=$("$CASE_TOOL" close 2>&1) || no_case_close_rc=$?
assert_eq "close with no active case fails" "1" "$no_case_close_rc"
assert_contains "close error mentions no active case" "No active case" "$no_case_close"

test_finish
