#/bin/bash

source ./setup_moveto_src.sh

mkdir ./dummy/qr_codes
mkdir ./dummy/decoded

give_access

head -c 4096 </dev/urandom > ./dummy/dummy_file.dat

DIGEST_IN=$(sha512sum dummy/dummy_file.dat | awk '{print $1;}')

./qrdump.sh --base64 --encode --output ./dummy/qr_codes --input dummy/dummy_file.dat

./qrdump.sh --base64 --decode --output ./dummy/decoded/ --input dummy/qr_codes/

DIGEST_OUT=$(sha512sum dummy/decoded/dummy_file.dat | awk '{print $1;}')

if [[ "${DIGEST_IN}" = "${DIGEST_OUT}" ]]
then
    echo "RES success restoring"
else
    echo "RES non identical file"
    exit 1
fi

press_any

source ../tests/rigup_moveto_test.sh
