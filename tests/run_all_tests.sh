#!/bin/bash

QRDUMP_QUICKTEST="False"

TERM_RED='\033[0;31m'
TERM_GREEN='\033[0;32m'
TERM_YELLOW='\033[0;33m'
TERM_NC='\033[0m'
TERM_BOLD='\033[1m'
TERM_NORMAL='\033[0m'

QRDUMP_TEST_FAILED=""

for QRDUMP_CRRT_ARG in "$@"; do
    case $QRDUMP_CRRT_ARG in
        --quick-test)
            QRDUMP_QUICKTEST="True"
            ;;
        *)
            echo "Unknown arg to run_all_testssh: $QRDUMP_CRRT_ARG"
            exit 1
            ;;
    esac
done

# TODO: make it possible to run in a verbose way

# exit if a command fails
set -o errexit
# make sure to show the error code of the first failing command
set -o pipefail
# do not overwrite files too easily
set -o noclobber
# exit if try to use undefined variable
set -o nounset

for CRRT_TEST in $(ls test_*\.sh) ; do
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"

    if [ $QRDUMP_QUICKTEST = "True" ]; then
        if [[ "$CRRT_TEST" == *_slow_* ]]; then
            echo "running with --quick-test, jump over slow $CRRT_TEST"
            continue
        fi
    fi

    echo "running test $CRRT_TEST"

    EXIT_CODE=0
    bash $CRRT_TEST ||  EXIT_CODE=$?

    if [ "$EXIT_CODE" = 0 ]; then
        echo -e "${TERM_GREEN} SUCCESS ${TERM_NC}"
    else
        echo -e "${TERM_RED} FAIL ${TERM_NC}"
        QRDUMP_TEST_FAILED="${QRDUMP_TEST_FAILED} ${CRRT_TEST}"
    fi
done

echo " "
echo -e "${TERM_YELLOW}%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%${TERM_NC}"
if [ "$QRDUMP_TEST_FAILED" = "" ]; then
    echo -e "${TERM_BOLD}${TERM_GREEN}All tests passed ${TERM_NC} ${TERM_NORMAL}"
    echo -e "${TERM_YELLOW}%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%${TERM_NC}"
    exit 0
else
    echo -e "${TERM_BOLD}${TERM_RED}Some tests failed: ${TERM_NC} ${TERM_NORMAL}"
    echo -e "${TERM_RED}  ${QRDUMP_TEST_FAILED} ${TERM_NC}"
    echo -e "${TERM_YELLOW}%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%${TERM_NC}"
    exit 1
fi
