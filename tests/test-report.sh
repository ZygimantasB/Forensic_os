#!/usr/bin/env bash
# Tests for forensic-report tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"

REPORT_TOOL="$SCRIPT_DIR/../tools/forensic-report"
CASE_TOOL="$SCRIPT_DIR/../tools/forensic-case"

test_start "forensic-report tests"

# ---- Sanity checks -----------------------------------------------------------
test_section "Sanity checks"

assert_file_exists "forensic-report tool exists" "$REPORT_TOOL"
assert_executable "forensic-report is executable" "$REPORT_TOOL"

shebang=$(head -1 "$REPORT_TOOL")
assert_contains "has proper shebang" "#!/usr/bin/env bash" "$shebang"

# ---- Help / usage output -----------------------------------------------------
test_section "Help / usage output"

help_output=$("$REPORT_TOOL" --help 2>&1 || true)
assert_contains "help shows Usage" "Usage" "$help_output"
assert_contains "help mentions generate" "generate" "$help_output"
assert_contains "help mentions summary" "summary" "$help_output"
assert_contains "help mentions -c flag" "CASE_DIR" "$help_output"

no_args_output=$("$REPORT_TOOL" 2>&1 || true)
assert_contains "no args shows usage" "Usage" "$no_args_output"

# ---- Set up test case --------------------------------------------------------
test_section "Set up test case"

export FORENSIC_CASES_DIR="$TEST_TMPDIR/cases"
export TEMPLATE_DIR="$SCRIPT_DIR/../templates"
mkdir -p "$FORENSIC_CASES_DIR"

CASE_NUM="2026-TEST-RPT"
EXAMINER="Report Tester"
DESCRIPTION="Report generation test case"

init_output=$("$CASE_TOOL" init -n "$CASE_NUM" -e "$EXAMINER" -d "$DESCRIPTION" 2>&1)
init_rc=$?
assert_exit_code "test case init succeeds" "0" "$init_rc"

CASE_DIR="$FORENSIC_CASES_DIR/$CASE_NUM"
assert_dir_exists "test case dir exists" "$CASE_DIR"

# Add a dummy evidence file so report has something to show
echo "evidence data for testing" > "$CASE_DIR/evidence/sample.bin"

# ---- Test generate command produces HTML output ------------------------------
test_section "Generate HTML report"

gen_output=$("$REPORT_TOOL" generate 2>&1)
gen_rc=$?
assert_exit_code "generate exits successfully" "0" "$gen_rc"
assert_contains "generate output mentions report" "report" "$gen_output"

REPORT_FILE="$CASE_DIR/reports/forensic-report-${CASE_NUM}.html"
assert_file_exists "HTML report file created" "$REPORT_FILE"
assert_file_not_empty "HTML report file is not empty" "$REPORT_FILE"

# ---- Verify HTML contains case number, examiner, date -----------------------
test_section "Verify HTML report content"

assert_file_contains "HTML contains case number" "$CASE_NUM" "$REPORT_FILE"
assert_file_contains "HTML contains examiner name" "$EXAMINER" "$REPORT_FILE"
# The report date uses current date, check for year at minimum
current_year=$(date +%Y)
assert_file_contains "HTML contains current year" "$current_year" "$REPORT_FILE"
assert_file_contains "HTML contains html tag" "<html" "$REPORT_FILE"

# ---- Test summary command ----------------------------------------------------
test_section "Summary command"

summary_output=$("$REPORT_TOOL" summary 2>&1)
summary_rc=$?
assert_exit_code "summary exits successfully" "0" "$summary_rc"
assert_contains "summary shows case number" "$CASE_NUM" "$summary_output"
assert_contains "summary shows examiner" "$EXAMINER" "$summary_output"
assert_contains "summary shows description" "$DESCRIPTION" "$summary_output"
assert_contains "summary shows status" "OPEN" "$summary_output"

# ---- Test with explicit -c flag ----------------------------------------------
test_section "Explicit -c flag"

# Remove .current_case so tool must rely on -c
rm -f "$FORENSIC_CASES_DIR/.current_case"

summary_c_output=$("$REPORT_TOOL" summary -c "$CASE_DIR" 2>&1)
summary_c_rc=$?
assert_exit_code "summary with -c exits successfully" "0" "$summary_c_rc"
assert_contains "summary -c shows case number" "$CASE_NUM" "$summary_c_output"

gen_c_output=$("$REPORT_TOOL" generate -c "$CASE_DIR" -o "$TEST_TMPDIR/explicit-report.html" 2>&1)
gen_c_rc=$?
assert_exit_code "generate with -c exits successfully" "0" "$gen_c_rc"
assert_file_exists "explicit output report created" "$TEST_TMPDIR/explicit-report.html"
assert_file_not_empty "explicit output report is not empty" "$TEST_TMPDIR/explicit-report.html"

# ---- Test with missing case dir fails gracefully -----------------------------
test_section "Missing case directory"

rm -f "$FORENSIC_CASES_DIR/.current_case"

missing_rc=0
missing_output=$("$REPORT_TOOL" generate -c "$TEST_TMPDIR/nonexistent-case" 2>&1) || missing_rc=$?
assert_eq "generate with missing case dir fails" "1" "$missing_rc"
assert_contains "error mentions no case directory" "No case directory\|not found\|case.json" "$missing_output"

missing_summary_rc=0
missing_summary=$("$REPORT_TOOL" summary -c "$TEST_TMPDIR/nonexistent-case" 2>&1) || missing_summary_rc=$?
assert_eq "summary with missing case dir fails" "1" "$missing_summary_rc"

# Test with no active case and no -c flag
no_case_rc=0
no_case_output=$("$REPORT_TOOL" generate 2>&1) || no_case_rc=$?
assert_eq "generate with no active case fails" "1" "$no_case_rc"
assert_contains "error about no case" "No case directory\|not found" "$no_case_output"

test_finish
