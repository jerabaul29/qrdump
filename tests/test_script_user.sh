#/bin/bash

source ./boilerplate.sh

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
