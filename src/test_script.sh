#/bin/bash

# a small set of tests of the qrdump tools
# TODO: move to its own folder
# TODO: automate testing
# TODO: increase coverage

########################################
# test of encoding / decoding base64   #
########################################

mkdir dummy
cd dummy
head -c 4096 </dev/urandom > dummy_file.dat
