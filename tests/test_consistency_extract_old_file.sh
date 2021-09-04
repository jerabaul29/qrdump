#/bin/bash

source ./setup_moveto_src.sh

mkdir ./dummy/generated_pdf
mkdir ./dummy/restored_result

DIGEST_IN="3c1e723a2258d013e9a32b06da1b343547cd7dffd4993077516d643661f1aea4be3214b06da1ca08467a9f6d44b3cf41c9ecbf772642f82cdf3efe3f44218317"

./qrdump.sh --create-A4 --base64 --output ./dummy/generated_pdf/my_pdf.pdf --input ./dummy/dummy_file.dat --metadata "a very special metadata"

./qrdump.sh --read-A4 --base64 --output ./dummy/restored_result/ --input ./dummy/generated_pdf/my_pdf.pdf

DIGEST_OUT=$(sha512sum dummy/restored_result/dummy_file.dat | awk '{print $1;}')

source ../tests/rigup_moveto_test.sh
