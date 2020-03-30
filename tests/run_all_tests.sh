#!/bin/bash

# exit if a command fails
set -o errexit
# make sure to show the error code of the first failing command
set -o pipefail
# do not overwrite files too easily
set -o noclobber
# exit if try to use undefined variable
set -o nounset

for CRRT_TEST in $(ls test_*\.sh) ; do
    echo "--------------------------------------------------"
    echo "running test $CRRT_TEST"

    bash $CRRT_TEST

done
