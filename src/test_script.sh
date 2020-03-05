#/bin/bash

# a small set of tests of the qrdump tools
# TODO: move to its own folder
# TODO: automate testing
# TODO: increase coverage

##############################################
# sounder programming environment            #
##############################################

# exit if a command fails
set -o errexit
# make sure to show the error code of the first failing command
set -o pipefail
# do not overwrite files too easily
set -o noclobber
# exit if try to use undefined variable
set -o nounset

########################################
# helper functions                     #
########################################

press_any(){
    echo "giving a chance to inspect the output"
    read -n 1 -s -r -p "Press any key to continue"
    echo " "
}

########################################
# test of encoding / decoding base64   #
########################################

mkdir dummy
cd dummy

head -c 4096 </dev/urandom > dummy_file.dat

press_any
cd ..
rm -rf dummy
