
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
# test API of direct to / from A4      #
########################################

if [ -d "dummy" ]
then
    echo "dir dummy for tests already exists; cleaning!"
    rm -rf dummy
fi

mkdir dummy
cd dummy
mkdir generated_pdf
mkdir restored_result

give_access

head -c 4096 </dev/urandom > dummy_file.dat

cd ..

DIGEST_IN=$(sha512sum dummy/dummy_file.dat | awk '{print $1;}')
echo "digest of the random file:"
echo ${DIGEST_IN}

bash ./qrdump.sh --create-A4 --base64 --safe-mode --output ./dummy/generated_pdf/my_pdf.pdf ./dummy/dummy_file.dat

echo "the pdf has been generated"
sleep 10
press_any

bash ./qrdump.sh --recover --base64 --output ./dummy/restored_result/ ./dummy/generated_pdf/my_pdf.pdf

DIGEST_OUT=$(sha512sum dummy/restored_result/dummy_file.dat | awk '{print $1;}')
echo "digest of the decrypted file:"
echo ${DIGEST_OUT}

if [[ "${DIGEST_IN}" = "${DIGEST_OUT}" ]]
then
    echo "success restoring!"
else
    echo "non identical file!"
    exit 1
fi

press_any

rm -rf dummy
