#!/bin/bash

# TODO: make it work in base64 encoding: dumping + extraction of metadata + 1 qr code
# then metadata + several QR codes

# TODO: automatic layout on A4 page, automatic extraction of layout on A4 page,
# add some lines of text

# TODO: automatic tests for development

# TODO: move into an own repo, and make it into 'qrdump'
# TODO: use 1 script to do all, both dump and extract?

# NOTE: used some inspiration for making
# more robust and parsing args from the second
# answer in:
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

# TODO: improve style
# https://bash3boilerplate.sh/

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

##############################################
# parse incoming args                        #
##############################################

# -allow a command to fail with !’s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

# acceptable options
OPTIONS=hvdg
LONGOPTS=help,verbose,base64,debug,digest:,

# TODO: add the --dump - d and the --extract -e options
# TODO: to allow the previous, change --debug -d to -b --debug

# default values of the options
HELP="False"
VERBOSE="False"
ENCODING="binary"  # TODO: add to options; use base64 so long
DEBUG="False"
DIGEST="sha1sum"

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi

# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -h|--help)
            HELP="True"
            shift
            ;;
        -v|--verbose)
            VERBOSE="True"
            shift
            ;;
        --base64)
            ENCODING="base64"
            shift
            ;;
        -d|--debug)
            DEBUG="True"
            shift
            ;;
        -g|--digest)
            DIGEST="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Invalid args; type -h or --help for help"
            exit 3
            ;;
    esac
done

if [[ "${HELP}" = "True" ]]; then
  echo "A bash script to generate a series of qr-codes"
  echo "to archive a file."
  echo "use: qrarchive file_name"
  echo "ex : qrarchive my_file.txt"
  exit 0
fi

# handle non-option arguments
if [[ $# -ne 1 ]]; then
    echo "$0: A single input file is required."
    exit 4
fi

# TODO: harmonize exit codes

##############################################
# input sanitation                           #
##############################################

FILE_NAME=$1
echo_verbose "qr-code archiving of ${FILE_NAME}"

if [ ! -f ${FILE_NAME} ]; then
    echo "File not found! Aborting..."
    exit 5
fi


##############################################
# critical verbose and debug functions       #
##############################################

echo_verbose(){
    if [[ "${VERBOSE}" = "True" ]]; then
        echo "$1"
    fi
}

show_debug_variable(){
    if [[ "${DEBUG}" = "True" ]]
    then
        local CRRT_VAR=$1
        echo "${CRRT_VAR}: ${!CRRT_VAR}"
    fi
}


##############################################
# in case of debug, show the options         #
##############################################

show_debug_variable "HELP"
show_debug_variable "VERBOSE"
show_debug_variable "ENCODING"
show_debug_variable "DEBUG"
show_debug_variable "DIGEST"


# TODO: add description / manpage (see what is below)

# generate a series of qr codes that fully encode a file
# workflow:
#
# create a temporary folder
#    compress
#    split
#    generate metadata
#    digest on all splits
#    generate the qr codes on all splits
#    copy the result to local dir
# destroy temporary folder
#
# 1st qr-code: metadata
#    - list of program versions used
#    - total number of data qr codes
#    - digest algorithm command
#    - compress algorithm command
#    - metadata
#    - user message
#
# following qr-codes: data segments
#
# output is 1 folder containing the "segment_0" (metadata) and
# the "segment_XX", containing the data.

# TODO: check that all needed packages are installed
# zbarimg --version
# qrencode
# gzip
# 

echo_verbose "start qr-code archiving..."

##############################################
# parameters processing and                  #
# parameters dependent functions             #
##############################################

# TODO: give several possible including none
# the digest function to use
# this is not for cryptographic reasons,
# only as a strong proof that the data
# was well decrypted
digest_function(){
    # digest and return the result converted in raw bytes
    # argument is either filename or read from std input
    # similar to the sha*sum functions

    # # if need to test this function
    # 
    # echo "baseline sha1sum"
    # echo -n "bla" | sha1sum
    # 
    # echo "try my function in std input mode"
    # echo -n "bla" | digest_function | xxd
    # 
    # echo "try my function in file name mode"
    # echo -n "bla" > crrt_digest_function_testfile.bin
    # digest_function crrt_digest_function_testfile.bin | xxd
    # rm crrt_digest_function_testfile.bin
    # echo "all should agree; done with my tests"

    # TODO: factor out as a function
    # find out what kind of data input is used ---------------------
    # if giving the filepath as argument
    if [[ "$#" = "1" ]]
    then
        # this needs to be a file that exists
        if [ ! -f $1 ]
        then
            echo "File not found! Aborting..."
            exit 6
        else
            # success, file is here
            local ARGTYPE="Filename"
            local PARAM="$1"
        fi

    # if giving data directly from std input
    else
        local ARGTYPE="StdInput"
        local PARAM=$(cat)
    fi

    # actually do the work ----------------------------------------
    # if using filepath
    if [[ "${ARGTYPE}" = "Filename" ]]
    then
        if [[ "${DIGEST}" = "sha1sum" ]]
        then
            local DIGEST=$(sha1sum ${PARAM})
        else
            echo "unknown DIGEST ${DIGEST}"
            exit 7
        fi

    # if using std input
    else
        if [[ "${DIGEST}" = "sha1sum" ]]
        then
            local DIGEST=$(echo -n ${PARAM} | sha1sum)
        else
            echo "unknown DIGEST ${DIGEST}"
            exit 7
        fi
    fi

    echo -n "${DIGEST}" | awk '{print $1;}' | xxd -r -ps
}

SIZE_DIGEST=$(echo -n "anything" | digest_function | wc -c)
show_debug_variable "SIZE_DIGEST"

# TODO: decide this so that use a 'good' size of individual qr codes
# the max information content of a qr-code depending
# of its size is given by the 'version table'.
# see for example: https://web.archive.org/web/20160326120122/http://blog.qr4.nl/page/QR-Code-Data-Capacity.aspx
# be a bit conservative about qr code size
# to be nice to possible bad printers
# TODO: automatically get the digest function size
# TODO: make this size an arg
MAX_QR_SIZE=403
show_debug_variable "MAX_QR_SIZE"

# TODO: make this full logics
# TODO: both the general ID (8 bytes) and the rank (2 bytes, TODO: make adaptable) should be made into logics
CONTENT_QR_CODE_BYTES=$((${MAX_QR_SIZE}-${SIZE_DIGEST}-2-8))
show_debug_variable "CONTENT_QR_CODE_BYTES"

# TODO: some print of the content per qr code

# TODO: some verbose control

# TODO: some choices of metadata

# TODO: some checks of 'well encoded data'

# TODO: some decoding function

# TODO: what this package is doing / not doing
# help in splitting / putting together
# no encryption or malicious user

# generate a random signature ID for the package
SIZE_ID=8
ID=$(dd if=/dev/urandom bs=${SIZE_ID} count=1 status=none)
echo_verbose "random ID:"
echo_verbose -n ${ID} | xxd

# TODO: function to organize the scanned QR codes
# for printing

# TODO function for ordering the collected QR codes

# TODO: app for scanning on the phone or from
# paper

# TODO: function for putting on paper
# first page: 'title, metadata, etc'
# following: data
# use A4 format
# typically 1mm minimum per mini block

# TODO: first page metadata: include how things
# organized on paper sheets when printing (so
# that more easy to decrypt).

# TODO: organize in functions, in particular
# the qr encoding / decoding
# and make the effective dots a bit bigger?

# TODO: apply formatting on how the QR codes
# put on the page. 1st page just metadata QR code
# later pages line top with page number.

# TODO: option base64 and log it in metadata

# TODO: verbosity control

# TODO: debug mode where shows the tmp stuff
# and do not remove it

##############################################
# ready to do the heavy work                 #
##############################################

# TODO: have a 'main functions section'

# create temporary folder
TMP_DIR=$(mktemp -d)
echo_verbose "created working tmp: ${TMP_DIR}"

# compress the destination file
# display information, use maximum compression
echo_verbose "compressing file..."
gzip -vc9 ${FILE_NAME} > ${TMP_DIR}/compressed

echo_verbose "information about compressed binary file:"
ls -lrth ${TMP_DIR}/compressed

# split the compressed file
# into segments to be used for qr-codes.
echo_verbose "split the compressed file into segments"
split -d -a 2 -b ${CONTENT_QR_CODE_BYTES} ${TMP_DIR}/compressed ${TMP_DIR}/data-

NBR_DATA_SEGMENTS=$(find ${TMP_DIR} -name 'data-*' | wc -l)
echo_verbose "split into ${NBR_DATA_SEGMENTS} segments"

# append for each data segment its digest
# the ID, and current segment number
COUNTER=0

for CRRT_FILE in ${TMP_DIR}/data-??; do
    echo_verbose "append digest ID to ${CRRT_FILE}"

    digest_function ${CRRT_FILE} >> ${CRRT_FILE}

    echo -n "${ID}" >> ${CRRT_FILE}

    # NOTE: this limits the max number of segments to 2^16-1 as
    # we are using 2 bytes for encoding
    printf "0: %.4x" $COUNTER | xxd -r -g0 >> ${CRRT_FILE}
    COUNTER=$((COUNTER+1))
done

# generate the data segments qr codes
for CRRT_FILE in ${TMP_DIR}/data-??; do
    echo_verbose "generate the qr-code for ${CRRT_FILE}"

    # use highest error correction level
    # TODO: adjust parameters to get nice sharp qr codes to print on A4
    cat ${CRRT_FILE} | qrencode -l H -8 -o ${CRRT_FILE}.png
done

# generate the qr code with the metadata
echo_verbose "create meteadata"

CRRT_FILE=${TMP_DIR}/metadata
echo -n "QRD:" >> ${CRRT_FILE}
echo "$(basename ${FILE_NAME})" >> ${CRRT_FILE}

echo -n "NSEG:" >> ${CRRT_FILE}
echo "${NBR_DATA_SEGMENTS}" >> ${CRRT_FILE}

echo -n "DATE:" >> ${CRRT_FILE}
echo "$(date '+%Y-%m-%d,%H:%M:%S')" >> ${CRRT_FILE}

echo -n "ID:" >> ${CRRT_FILE}
echo "${ID}" >> ${CRRT_FILE}

echo -n "vGZIP:" >> ${CRRT_FILE}
echo "$(gzip --version | head -1 | awk '{print $2}')" >> ${CRRT_FILE}

echo -n "vQRENCODE:" >> ${CRRT_FILE}
echo "$(qrencode --version 2>&1 | head -1 |  awk '{print $3}')" >> ${CRRT_FILE}

echo -n "SYS:" >> ${CRRT_FILE}
echo "$(lsb_release -d | cut -f 2- -d$'\t' | sed 's/ //g')" >> ${CRRT_FILE}

# check that metadata is not too heavy
# use the same size as the max qrcode choosen previously
if [ "$(stat --printf="%s" ${CRRT_FILE})" -gt ${MAX_QR_SIZE} ]; then
    echo_verbose "*** WARNING *** looks like the metadata is dangerously big!"
fi

echo_verbose "generate metadata qr code"
cat ${CRRT_FILE} | qrencode -l H -8 -o ${CRRT_FILE}.png

# check that able to decode all and agree with the input data
# TODO: for all in png decrypt and compare with the non png

# TODO: put on an A4 page

# TODO: the encoding / decoding with QR codes is broken for now because
# probably of what zbarimg does when the qr code contains some binary
# data, see:
# https://stackoverflow.com/questions/60506222/encode-decode-binary-data-in-a-qr-code-using-qrencode-and-zbarimg-in-bash
# trying to get a version of zbarimg that does not break the binary
# encoding thing. Another option as suggested on SO is to use
# a base64 encoding, but I am afraid that it will reduce the
# capacity by a factor of 2.
# a fix to zbarimg is under its way and should solve the problem.


# move all the qr codes to a new folder
# at the current location

# delete temporary folder
if [[ "${DEBUG}" = "True" ]];
then
    echo "in debug mode, the tmp dir is not removed to allow inspection"
    echo "tmp is found in: ${TMP_DIR}"
else
    echo_verbose "removed working tmp: ${TMP_DIR}"
    rm -r $TMP_DIR
fi

echo_verbose "done"



# TODO: have a 'main' section where most of the actual
# work is done

















