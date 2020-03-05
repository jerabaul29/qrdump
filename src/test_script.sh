#/bin/bash

# a small set of tests of the qrdump tools
# TODO: move to its own folder
# TODO: automate testing
# TODO: increase coverage
# TODO: use fully extended options for lisibility

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
# test of encoding / decoding base64   #
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

# TODO: take sha of it
DIGEST_IN=$(sha512sum dummy_file.dat | awk '{print $1;}' | xxd -r -ps)
echo "digest of the random file:"
echo ${DIGEST_IN}

bash ../qrdump.sh --base64 -b -e -v dummy_file.dat

echo "encoding finished"
# TODO: maybe cleaning should be done another place or something like that
echo "clean the initial file"
mv dummy_file.dat dummy_file_start.dat

# need to sleep a bit to make sure all files well written
sleep 5


cd ..

press_any

# TODO: clean
# TODO: decode
bash ./qrdump.sh --base64 -b -d -v dummy

echo "decoding finished"
press_any
DIGEST_OUT=$(sha512sum dummy/dummy_file.dat | awk '{print $1;}' | xxd -r -ps)
echo "digest of the decrypted file:"
echo ${DIGEST_OUT}

if [[ "${DIGEST_IN}" = "${DIGEST_OUT}" ]]
then
    echo "success restoring!"
else
    echo "non identical file!"
    exit 1
fi

# TODO: take sha of decoded and check integrity

rm -rf dummy
