#/bin/bash

# a small set of tests of the qrdump tools
# TODO: move to its own folder
# TODO: automate testing
# TODO: increase coverage
# TODO: use fully extended options for lisibility

mkdir dummy
cd dummy

mkdir qr_codes
mkdir decoded

give_access

head -c 4096 </dev/urandom > dummy_file.dat

cd ..

DIGEST_IN=$(sha512sum dummy/dummy_file.dat | awk '{print $1;}')
echo "digest of the random file:"
echo ${DIGEST_IN}

./qrdump.sh --base64 -b --encode -v --output ./dummy/qr_codes dummy/dummy_file.dat

echo "encoding finished"

echo "WAIT SO THAT FILES ARE FULLY COPIED, OTHERWISE ERROR"
sleep 10

press_any

bash ./qrdump.sh --base64 -b --decode -v --output ./dummy/decoded/ dummy/qr_codes/

echo "decoding finished"
press_any
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

# TODO: take sha of decoded and check integrity

rm -rf dummy
