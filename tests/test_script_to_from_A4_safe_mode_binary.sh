#/bin/bash

echo "Jumping over this test for now; need Ubuntu 21.04 or higher"
echo "and this is not yet available as a virtual environment for"
echo "Github actions."

# source ./setup_moveto_src.sh
# 
# mkdir ./dummy/generated_pdf
# mkdir ./dummy/restored_result
# 
# DIGEST_IN=$(sha512sum dummy/dummy_file.dat | awk '{print $1;}')
# 
# ./qrdump.sh --create-A4 --safe-mode --output ./dummy/generated_pdf/my_pdf.pdf --input ./dummy/dummy_file.dat
# 
# ./qrdump.sh --read-A4 --output ./dummy/restored_result/ --input ./dummy/generated_pdf/my_pdf.pdf
# 
# DIGEST_OUT=$(sha512sum dummy/restored_result/dummy_file.dat | awk '{print $1;}')
# 
# source ../tests/rigup_moveto_test.sh
