#/bin/bash

source ./setup_moveto_src.sh

mkdir ./dummy/generated_pdf
mkdir ./dummy/restored_result

DIGEST_IN=$(sha512sum dummy/dummy_file.dat | awk '{print $1;}')

QRDUMP_TEST_CRRT_CWD=$(pwd)
QRDUMP_TEST_ABSOLUTE_OUTPUT="${QRDUMP_TEST_CRRT_CWD}/./dummy/generated_pdf/my_pdf.pdf"
QRDUMP_TEST_ABSOLUTE_INPUT="${QRDUMP_TEST_CRRT_CWD}/./dummy/dummy_file.dat"
./qrdump.sh --create-A4 --base64 --output ${QRDUMP_TEST_ABSOLUTE_OUTPUT} --input ${QRDUMP_TEST_ABSOLUTE_INPUT}

# TODO: add a dir for working in ~
QRDUMP_TEST_PATH_TESTFOLDER_HOME=~/.test_qrdump_home_path

if [ -d  "$QRDUMP_TEST_PATH_TESTFOLDER_HOME" ]; then
    echo "home test folder $QRDUMP_TEST_PATH_TESTFOLDER_HOME already exists, cleaning..."
    rm -rf "$QRDUMP_TEST_PATH_TESTFOLDER_HOME"
fi

$(mkdir "$QRDUMP_TEST_PATH_TESTFOLDER_HOME")
QRDUMP_TEST_PATH_TESTFOLDER_HOME="${QRDUMP_TEST_PATH_TESTFOLDER_HOME}/"

./qrdump.sh --read-A4 --base64 --output "$QRDUMP_TEST_PATH_TESTFOLDER_HOME" --input "${QRDUMP_TEST_ABSOLUTE_OUTPUT}"

DIGEST_OUT=$(sha512sum $QRDUMP_TEST_PATH_TESTFOLDER_HOME/dummy_file.dat | awk '{print $1;}')

rm -rf "$QRDUMP_TEST_PATH_TESTFOLDER_HOME"
source ../tests/rigup_moveto_test.sh
