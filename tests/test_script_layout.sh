#/bin/bash

source ./boilerplate.sh

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
