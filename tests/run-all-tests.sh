#!/usr/bin/env bash
# =============================================================================
# run-all-tests.sh - ForensicOS Test Runner
# =============================================================================
# Runs all test-*.sh scripts in the tests/ directory and reports results.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0
FAILED_TESTS=()

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║       ForensicOS Test Suite Runner           ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# Collect test files (exclude framework and runner)
TEST_FILES=()
for f in "$SCRIPT_DIR"/test-*.sh; do
    [[ "$(basename "$f")" == "test-framework.sh" ]] && continue
    [[ -x "$f" ]] || continue
    TEST_FILES+=("$f")
done

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
    echo -e "${RED}No test files found!${NC}"
    exit 1
fi

echo -e "Found ${BOLD}${#TEST_FILES[@]}${NC} test files."
echo ""

# Run each test
for test_file in "${TEST_FILES[@]}"; do
    test_name="$(basename "$test_file" .sh)"
    echo -e "${BOLD}━━━ Running: ${test_name} ━━━${NC}"

    # Capture output and exit code
    output=$( bash "$test_file" 2>&1 )
    exit_code=$?

    echo "$output"

    # Parse results from output
    pass=$(echo "$output" | grep -oP '\d+(?= passed)' | tail -1 || echo 0)
    fail=$(echo "$output" | grep -oP '\d+(?= failed)' | tail -1 || echo 0)
    skip=$(echo "$output" | grep -oP '\d+(?= skipped)' | tail -1 || echo 0)

    TOTAL_PASS=$((TOTAL_PASS + ${pass:-0}))
    TOTAL_FAIL=$((TOTAL_FAIL + ${fail:-0}))
    TOTAL_SKIP=$((TOTAL_SKIP + ${skip:-0}))

    if [[ $exit_code -ne 0 ]]; then
        FAILED_TESTS+=("$test_name")
    fi

    echo ""
done

# Summary
TOTAL=$((TOTAL_PASS + TOTAL_FAIL + TOTAL_SKIP))

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║              TEST SUITE RESULTS              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${GREEN}Passed : ${TOTAL_PASS}${NC}"
echo -e "  ${RED}Failed : ${TOTAL_FAIL}${NC}"
echo -e "  ${YELLOW}Skipped: ${TOTAL_SKIP}${NC}"
echo -e "  ${BOLD}Total  : ${TOTAL}${NC}"
echo ""

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo -e "${RED}Failed test suites:${NC}"
    for ft in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} ${ft}"
    done
    echo ""
    exit 1
else
    echo -e "${GREEN}All test suites passed!${NC}"
    echo ""
    exit 0
fi
