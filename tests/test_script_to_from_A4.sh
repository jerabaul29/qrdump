#/bin/bash

source ./setup_moveto_src.sh

mkdir ./dummy/generated_pdf
mkdir ./dummy/restored_result

DIGEST_IN=$(sha512sum dummy/dummy_file.dat | awk '{print $1;}')

./qrdump.sh --debug --verbose --create-A4 --base64 --output ./dummy/generated_pdf/my_pdf.pdf --input ./dummy/dummy_file.dat

./qrdump.sh --debug --verbose --read-A4 --base64 --output ./dummy/restored_result/ --input ./dummy/generated_pdf/my_pdf.pdf

DIGEST_OUT=$(sha512sum dummy/restored_result/dummy_file.dat | awk '{print $1;}')

source ../tests/rigup_moveto_test.sh
