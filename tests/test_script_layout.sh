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

cd ../src/

if [ -d "dummy" ]
then
    echo "dir dummy for tests already exists; cleaning!"
    rm -rf dummy
fi

mkdir dummy
cd dummy
mkdir qr_codes
mkdir decoded
mkdir generated_pdf
mkdir extracted_A4_qr_codes

give_access

head -c 4096 </dev/urandom > dummy_file.dat

cd ..

DIGEST_IN=$(sha512sum dummy/dummy_file.dat | awk '{print $1;}')
echo "digest of the random file:"
echo ${DIGEST_IN}

./qrdump.sh --base64 -b --encode -v --output ./dummy/qr_codes ./dummy/dummy_file.dat

echo "encoding finished"

echo "WAIT SO THAT FILES ARE FULLY COPIED, OTHERWISE ERROR"
sleep 10

# generate the A4 dump
bash ./qrdump.sh --layout --base64 -b -v --output ./dummy/generated_pdf/my_pdf.pdf ./dummy/qr_codes

# extract QR codes from the A4
bash ./qrdump.sh --read-pdf --base64 -b -v --output ./dummy/extracted_A4_qr_codes dummy/generated_pdf/my_pdf.pdf

# decode
bash ./qrdump.sh --base64 -b -d -v --output dummy/decoded dummy/extracted_A4_qr_codes

DIGEST_OUT=$(sha512sum dummy/decoded/dummy_file.dat | awk '{print $1;}')
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
