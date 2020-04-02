#/bin/bash

source ./setup_moveto_src.sh

mkdir ./dummy/generated_pdf
mkdir ./dummy/restored_result

rm ./dummy/dummy_file.dat
head -c 100K </dev/urandom > ./dummy/dummy_file.dat
echo "testing with a 100K file, this may take a few seconds..."

DIGEST_IN=$(sha512sum dummy/dummy_file.dat | awk '{print $1;}')

./qrdump.sh --create-A4 --base64 --safe-mode --output ./dummy/generated_pdf/my_pdf.pdf --input ./dummy/dummy_file.dat

./qrdump.sh --read-A4 --base64 --output ./dummy/restored_result/ --input ./dummy/generated_pdf/my_pdf.pdf

DIGEST_OUT=$(sha512sum dummy/restored_result/dummy_file.dat | awk '{print $1;}')

source ../tests/rigup_moveto_test.sh
