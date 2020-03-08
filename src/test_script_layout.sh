#/bin/bash

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

# TODO: have a 'manual run' and an 'automatic run'
# option for running this. In manual automatic run
# make press_any do nothing and redirect to a log file

press_any(){
    echo "giving a chance to inspect the output"
    read -n 1 -s -r -p "Press any key to continue"
    echo " "
}

give_access(){
    nautilus . &
}

########################################
# test of encoding and A4 layout       #
########################################

if [ -d "dummy" ]
then
    echo "dir dummy for tests already exists; cleaning!"
    rm -rf dummy
fi

mkdir dummy
cd dummy

give_access

head -c 4096 </dev/urandom > dummy_file.dat

bash ../qrdump.sh --base64 -b -e -v dummy_file.dat

sleep 5

cd ..

bash ./qrdump.sh --layout --base64 -b -v dummy

press_any

rm -rf dummy
