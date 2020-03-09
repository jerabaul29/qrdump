#!/bin/bash

# TODO: make sure use fixed format for numberings, otherwise the ordering of the files is broken (10 is before 2)

# TODO: separate the different parts of the logics in different files, clean, etc

# TODO: user-defined message to put on all dumps instead of 'relevant metadata'

# TODO: make sure null bytes do not break stuff!
# TODO: metadata QR: give them a signature: title line METADATAQRDUMP or similar

# TODO: write a small bash function that cuts a file into a succession of segments
# and write them to different files. This could be used for splitting more efficiently
# the metadata

# TODO: metadata: put zbarimg

# TODO: make it work in base64 encoding: dumping + extraction of metadata + 1 qr code
# then metadata + several QR codes

# TODO: automatic layout on A4 page, automatic extraction of layout on A4 page,
# add some lines of text

# TODO: automatic tests for development

# TODO: let the user specify the output / output folder etc

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
OPTIONS=hvbg:edlro:
LONGOPTS=help,verbose,base64,debug,digest:,encode,decode,layout,read-pdf,output:

# TODO: add the --dump - d and the --extract -e options
# TODO: to allow the previous, change --debug -d to -b --debug

# default values of the options
HELP="False"
VERBOSE="False"
ENCODING="binary"  # TODO: add to options; use base64 so long
DEBUG="False"
DIGEST="sha1sum"
ACTION="None"
OUTPUT="None"

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
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
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
        -b|--debug)
            DEBUG="True"
            shift
            ;;
        -g|--digest)
            DIGEST="$2"
            shift 2
            ;;
        -e|--encode)
            ACTION="Encode"
            shift
            ;;
        -d|--decode)
            ACTION="Decode"
            shift
            ;;
        -l|--layout)
            ACTION="Layout"
            shift
            ;;
        -r|--read-pdf)
            ACTION="ReadPDF"
            shift
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
    echo "$0: A single input file or folder is required."
    exit 4
fi

# TODO: harmonize exit codes

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

show_debug_file_binary(){
    local CRRT_VAR=$1

    if [[ "${DEBUG}" = "True" ]]
    then
        # to avoid problems with null bytes, this MUST be read from file
        if [[ -f "${!CRRT_VAR}" ]]
        then
            echo "${CRRT_VAR}:"
            cat "${!CRRT_VAR}" | xxd
        else
            echo "*** WARNING *** no file available to read binary variable ${!CRRT_VAR}"
        fi
    fi
}


##############################################
# input sanitation                           #
##############################################

# check valid filename if encode
if [[ "${ACTION}" =~ ^(Encode|ReadPDF)$ ]]
then
    FILE_NAME=$1
    echo_verbose "qr-code archiving of ${FILE_NAME}"

    if [ ! -f ${FILE_NAME} ]; then
        echo "File not found! Aborting..."
        exit 5
    fi
fi

# for now request an output location: directory or filename
# NOTE: now asking for a directory no choice, may be bad, may want to change that later.
if [[ "${ACTION}" =~ ^(cat|Encode)$ ]]; then
    if [[ ${OUTPUT} = "None" ]]
    then
        echo "performing encode requires a folder destination for putting the QR codes!"
        exit 1
    fi
else
    if [[ ${OUTPUT} = "None" ]]
    then
        echo "performing decode | A4 layout | PDF reading requires a folder destination for putting the results!"
        exit 1
    fi
fi

# check valid folder if layout | decode
if [[ "${ACTION}" =~ ^(cat|Decode|Layout)$ ]]
then
    FOLDER_NAME=$1
    echo_verbose "qr-code decoding of ${FOLDER_NAME}"

    if [ ! -d ${FOLDER_NAME} ]; then
        echo "Folder not found! Aborting..."
        exit 5
    fi
fi

# check using base64 for now
if [[ "${ENCODING}" != "base64" ]]
then
    echo "at the moment, only base64 encoding is supported!"
    echo "see: https://stackoverflow.com/questions/60506222"
    echo "Aborting..."
    exit 1
fi

# check using valid action
if [[ "${ACTION}" =~ ^(cat|Encode|Decode|Layout|ReadPDF)$ ]]; then
    echo_verbose "valid action"
else
    echo "invalid action: ACTION is now ${ACTION}."
    echo "needs either -d|--decode or -e|--encode flag"
    echo "abortin..."
    exit 1
fi

##############################################
# in case of debug, show the options         #
##############################################

show_debug_variable "HELP"
show_debug_variable "VERBOSE"
show_debug_variable "ENCODING"
show_debug_variable "DEBUG"
show_debug_variable "DIGEST"
show_debug_variable "ACTION"
show_debug_variable "OUTPUT"

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


##############################################
# parameters processing and                  #
# parameters dependent functions             #
##############################################

n_last_bytes(){
    # write the last $1 bytes of file $2 to $3
    local FILESIZE=$(stat -c%s "$2")
    show_debug_variable "FILESIZE"

    local NBYTES_TO_CUT=$((${FILESIZE}-$1))
    show_debug_variable "NBYTES_TO_CUT"

    dd if="$2" of="$3" ibs="${NBYTES_TO_CUT}" skip=1 status=none
}

pad_png_image(){
    # $1 path to the png
    # $2 final X size
    # $3 final Y size
    # $4 path to generated png

    local PNG_IN=$1
    local FINAL_X_SIZE=$2
    local FINAL_Y_SIZE=$3
    local PNG_OUT=$4
    local BASE_FOLDER=$(dirname "${PNG_IN}")

    echo_verbose "pad png image ${PNG_IN}"

    # put the metadata qr code under
    local CRRT_PNG_X_SIZE=$(identify "${PNG_IN}" | awk '{print $3;}' | cut -d'x' -f1)
    local CRRT_PNG_Y_SIZE=$(identify "${PNG_IN}" | awk '{print $3;}' | cut -d'x' -f2)

    if [[ ${FINAL_X_SIZE} -le ${CRRT_PNG_X_SIZE} ]]
    then
        echo "*** ERROR *** the padded X size ${FINAL_X_SIZE} is smaller or equal than the input size ${CRRT_PNG_X_SIZE}"
        exit 1
    fi

    if [[ ${FINAL_Y_SIZE} -le ${CRRT_PNG_Y_SIZE} ]]
    then
        echo "*** ERROR *** the padded Y size ${FINAL_Y_SIZE} is smaller or equal than the input size ${CRRT_PNG_Y_SIZE}"
        exit 1
    fi

    show_debug_variable "CRRT_PNG_X_SIZE"
    show_debug_variable "CRRT_PNG_Y_SIZE"

    local ADD_RIGHT=$(( (${FINAL_X_SIZE}-${CRRT_PNG_X_SIZE}) / 2 ))
    local ADD_LEFT=$(( ${FINAL_X_SIZE} - ${CRRT_PNG_X_SIZE} - ${ADD_RIGHT}  ))

    local ADD_TOP=$(( (${FINAL_Y_SIZE} - ${CRRT_PNG_Y_SIZE}) / 2 ))
    local ADD_BOTTOM=$(( ${FINAL_Y_SIZE} - ${CRRT_PNG_Y_SIZE} - ${ADD_TOP} ))

    show_debug_variable "ADD_RIGHT"
    show_debug_variable "ADD_LEFT"

    show_debug_variable "ADD_TOP"
    show_debug_variable "ADD_BOTTOM"

    convert -size ${ADD_LEFT}x${CRRT_PNG_Y_SIZE} xc:white ${BASE_FOLDER}/left_margin.png
    convert -size ${ADD_RIGHT}x${CRRT_PNG_Y_SIZE} xc:white ${BASE_FOLDER}/right_margin.png

    convert ${BASE_FOLDER}/left_margin.png ${PNG_IN} ${BASE_FOLDER}/right_margin.png +append ${BASE_FOLDER}/padded_left_right.png

    echo_verbose "padded right left"

    convert -size ${FINAL_X_SIZE}x${ADD_TOP} xc:white ${BASE_FOLDER}/top_margin.png
    convert -size ${FINAL_X_SIZE}x${ADD_BOTTOM} xc:white ${BASE_FOLDER}/bottom_margin.png

    convert ${BASE_FOLDER}/top_margin.png ${BASE_FOLDER}/padded_left_right.png ${BASE_FOLDER}/bottom_margin.png -append ${PNG_OUT}

    echo "padded top bottom"

}

create_banner_of_qr_codes(){
    # arguments:
    # - first the banner number
    # - first folder name
    # - then the list of things to use for the banner
    echo_verbose "creating the banners with arguments..."
     for i in $*; do 
       echo_verbose $i 
     done

    # check that at least 3 args (ie the first 2 + at least 1 data qr code)
    if [ "$#" -lt 3 ]
    then
        echo "too few arguments to generate a banner!"
        exit 1
    fi

    local BANNER_NUMBER=$1
    local FOLDER_NAME=$2

    local FIRST_DATA_TO_USE=$3

    if [ "$#" -lt 4 ]
    then
        # need to create the second qr code as empty
        convert -size 269x269 xc:white ${FOLDER_NAME}/empty_padded_qr.png
        local SECOND_DATA_TO_USE="${FOLDER_NAME}/empty_padded_qr.png"
    else
        local SECOND_DATA_TO_USE=$4
    fi


    convert -size 23x269 xc:white ${FOLDER_NAME}/padding_banner_sides.png
    convert -size 11x269 xc:white ${FOLDER_NAME}/padding_banner_middle.png

    convert ${FOLDER_NAME}/padding_banner_sides.png ${FIRST_DATA_TO_USE} ${FOLDER_NAME}/padding_banner_middle.png ${SECOND_DATA_TO_USE} ${FOLDER_NAME}/padding_banner_sides.png +append ${FOLDER_NAME}/banner_${BANNER_NUMBER}.png

    # TODO: RESUMEHERE
    # if some data qr codes left, generate more banners
    if [ "$#" -gt 4 ]
    then
        local NEXT_BANNER_NUMBER=$(( ${BANNER_NUMBER} + 1 ))
        shift 4
        local NEXT_LIST_DATA_QR="$*"

        show_debug_variable "NEXT_BANNER_NUMBER"
        show_debug_variable "NEXT_LIST_DATA_QR"

        create_banner_of_qr_codes ${NEXT_BANNER_NUMBER} ${FOLDER_NAME} ${NEXT_LIST_DATA_QR}
    fi
}

int_with_5_digits(){
    printf "%05d\n" $1
}

int_with_2_digits(){
    printf "%02d\n" $1
}

extract_QR_codes_from_pages(){
    local BASE_FOLDER=$1
    local CRRT_QR_CODE_NBR=0

    echo_verbose "extract QR codes from pages..."

    for CRRT_PAGE in ${BASE_FOLDER}/extracted_A4_page_*\.png
    do
        # split the QR codes
        show_debug_variable "CRRT_PAGE"

        # first banner
        convert "${CRRT_PAGE}[297x269+0+32]" ${BASE_FOLDER}/data-$(int_with_2_digits ${CRRT_QR_CODE_NBR}).png
        CRRT_QR_CODE_NBR=$(( ${CRRT_QR_CODE_NBR} + 1  ))
        convert "${CRRT_PAGE}[297x269+297+32]" ${BASE_FOLDER}/data-$(int_with_2_digits ${CRRT_QR_CODE_NBR}).png
        CRRT_QR_CODE_NBR=$(( ${CRRT_QR_CODE_NBR} + 1  ))

        # second banner
        convert "${CRRT_PAGE}[297x269+0+302]" ${BASE_FOLDER}/data-$(int_with_2_digits ${CRRT_QR_CODE_NBR}).png
        CRRT_QR_CODE_NBR=$(( ${CRRT_QR_CODE_NBR} + 1  ))
        convert "${CRRT_PAGE}[297x269+297+302]" ${BASE_FOLDER}/data-$(int_with_2_digits ${CRRT_QR_CODE_NBR}).png
        CRRT_QR_CODE_NBR=$(( ${CRRT_QR_CODE_NBR} + 1  ))

        # third banner
        convert "${CRRT_PAGE}[297x269+0+572]" ${BASE_FOLDER}/data-$(int_with_2_digits ${CRRT_QR_CODE_NBR}).png
        CRRT_QR_CODE_NBR=$(( ${CRRT_QR_CODE_NBR} + 1  ))
        convert "${CRRT_PAGE}[297x269+297+572]" ${BASE_FOLDER}/data-$(int_with_2_digits ${CRRT_QR_CODE_NBR}).png
        CRRT_QR_CODE_NBR=$(( ${CRRT_QR_CODE_NBR} + 1  ))

    done
}

create_page_of_qr_banners(){
    # TODO: put a short text at the top (may need making a bit more space)

    echo_verbose "creating the banners with arguments..."
     for i in $*; do 
       echo_verbose $i 
     done

    # check that at least 3 args (ie the first 2 + at least 1 data qr code)
    if [ "$#" -lt 3 ]
    then
        echo "too few arguments to generate a banner!"
        exit 1
    fi

    local PAGE_NUMBER=$1
    local FOLDER_NAME=$2

    local FIRST_DATA_TO_USE=$3

    if [ "$#" -lt 5 ]
    then
        convert -size 595x269 xc:white ${FOLDER_NAME}/empty_padded_qr.png
        local THIRD_DATA_TO_USE="${FOLDER_NAME}/empty_padded_qr.png"
    else
        local THIRD_DATA_TO_USE=$5
    fi

    if [ "$#" -lt 4 ]
    then
        local SECOND_DATA_TO_USE="${FOLDER_NAME}/empty_padded_qr.png"
    else
        local SECOND_DATA_TO_USE=$4
    fi

    show_debug_variable "FIRST_DATA_TO_USE"
    show_debug_variable "SECOND_DATA_TO_USE"
    show_debug_variable "THIRD_DATA_TO_USE"

    echo -n "text 15,15   \"" >> ${FOLDER_NAME}/text_top.txt
    # TODO: put some relevant metadata
    echo "PAGE ${PAGE_NUMBER}; some relevant metadata" >> ${FOLDER_NAME}/text_top.txt
    echo -n "\"" >> ${FOLDER_NAME}/text_top.txt

    convert -size 595x32 xc:white -font "FreeMono" -pointsize 14 -fill black -draw @${FOLDER_NAME}/text_top.txt ${FOLDER_NAME}/padding_page_top.png

    rm ${FOLDER_NAME}/text_top.txt

    convert -size 595x1 xc:white ${FOLDER_NAME}/padding_page_middle.png
    convert -size 595x1 xc:white ${FOLDER_NAME}/padding_page_bottom.png

    convert ${FOLDER_NAME}/padding_page_top.png \
        ${FIRST_DATA_TO_USE} \
        ${FOLDER_NAME}/padding_page_middle.png \
        ${SECOND_DATA_TO_USE} \
        ${FOLDER_NAME}/padding_page_middle.png \
        ${THIRD_DATA_TO_USE} \
        ${FOLDER_NAME}/padding_page_bottom.png \
        -append \
        ${FOLDER_NAME}/data_page_${PAGE_NUMBER}.png

    # if some banners left, generate more banners
    if [ "$#" -gt 5 ]
    then
        local NEXT_PAGE_NUMBER=$(( ${PAGE_NUMBER} + 1 ))
        shift 5
        local NEXT_LIST_DATA_BANNER="$*"

        show_debug_variable "NEXT_PAGE_NUMBER"
        show_debug_variable "NEXT_LIST_DATA_BANNER"

        create_page_of_qr_banners ${NEXT_PAGE_NUMBER} ${FOLDER_NAME} ${NEXT_LIST_DATA_BANNER}
    fi
}

# TODO: give several digests possible including none
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
        if [[ ! -f $1 ]]
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

# TODO: consider factoring verbosity in the functions

perform_qr_encoding(){
    # arg 1: data file to encode into a QR-code
    # arg 2: destination where to put the QR-code

    local TO_ENCODE=$1
    local DESTINATION=$2

    # allow base64
    if [[ "${ENCODING}" = "base64"  ]]
    then
        base64 < ${TO_ENCODE} | qrencode -l M -8 -o ${DESTINATION}.png
    fi
}

# unfortunately, seems that need to do this from the body of the other 
# function otherwise the new variables are masked
read_metadata(){
    # NOTE: here using some global variables dark magics... dangerous!
    local PATH=$1
    local IFS=":"
    # TODO: fix uppper case convention in this function
    while read -r name value
    do
        echo $name
        # special treatment when debug display in case of binary data
        if [[ "${name}" = "ID" ]]
        then
            if [[ "${VERBOSE}" = "True" ]]
            then
                echo "FIXME HERE"
                # TODO: strange xxd command not found bug here
            #    echo -n ${value} | xxd
            fi
        else
            echo_verbose "Content of metadata field ${name} is ${value}"
        fi
        declare "${name}"="${value}"
    done < ${PATH}

    echo ${QRD}
}

perform_qr_decoding(){
    local TO_DECODE=$1
    local DESTINATION=$2

    echo_verbose "decoding ${TO_DECODE} into ${DESTINATION}"

    # allow base64
    if [[ "${ENCODING}" = "base64"  ]]
    then
        echo_verbose "using encoding base64"
        zbarimg --raw --quiet "${TO_DECODE}" | base64 -d > "${DESTINATION}"
    fi
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
# this is 69x69 pixels
MAX_QR_SIZE=331
show_debug_variable "MAX_QR_SIZE"
MAX_QR_SIZE_PIXELS=0

# the rank size in the data QR metadata
# TODO: allow to change if necessary
SIZE_RANK=2

# size of the ID
# TODO: make it argument
SIZE_ID=8

# TODO: make this full logics
# TODO: both the general ID (8 bytes) and the rank (2 bytes, TODO: make adaptable) should be made into logics
SIZE_DATAQR_METADATA=$((${SIZE_DIGEST}+${SIZE_RANK}+${SIZE_ID}))
CONTENT_QR_CODE_BYTES=$((${MAX_QR_SIZE}-SIZE_DATAQR_METADATA))

show_debug_variable "SIZE_DATAQR_METADATA"
show_debug_variable "CONTENT_QR_CODE_BYTES"

# TODO: some print of the content per qr code

# TODO: some verbose control

# TODO: some choices of metadata

# TODO: some checks of 'well encoded data'

# TODO: some decoding function

# TODO: what this package is doing / not doing
# help in splitting / putting together
# no encryption or malicious user


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

# TODO: allow dpi as arg
# DPI 72 is qrencode default
DPI=72

# size of QR code dots in pixels
# 3 is the default of qrencode following --size=NUMBER
# TODO: make as an argument
SIZE_QR_DOT=3



##############################################
# ready to do the heavy work                 #
##############################################


##############################################
# encoding in series of QR codes             #
##############################################

# TODO: split the logics in smaller functions

full_encode(){
    echo_verbose "start qr-code archiving..."

    # generate a random signature ID for the package
    ID=$(dd if=/dev/urandom bs=${SIZE_ID} count=1 status=none | tr '\r\n' ' ' | tr ':' ' ' )

    echo_verbose "random ID:"

    if [[ "${VERBOSE}" = "True" ]]
    then
        echo -n ${ID} | xxd
    fi

    # TODO: have a 'main functions section'

    # create temporary folder
    TMP_DIR=$(mktemp -d)
    echo_verbose "created working tmp: ${TMP_DIR}"

    # compress the destination file
    # display information, use maximum compression
    echo_verbose "compressing file..."
    gzip -vc9 ${FILE_NAME} > ${TMP_DIR}/compressed.gz

    echo_verbose "information about compressed binary file:"
    ls -lrth ${TMP_DIR}/compressed.gz

    # split the compressed file
    # into segments to be used for qr-codes.
    echo_verbose "split the compressed file into segments"
    split -d -a 2 -b ${CONTENT_QR_CODE_BYTES} ${TMP_DIR}/compressed.gz ${TMP_DIR}/data-

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
        perform_qr_encoding "${CRRT_FILE}" "${CRRT_FILE}"
    done

    # TODO: separate function to generate the metadata
    # (and separate function to decode the metadata)
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
    if [[ "$(stat --printf="%s" ${CRRT_FILE})" -gt ${MAX_QR_SIZE} ]]; then
        echo_verbose "*** WARNING *** looks like the metadata is dangerously big!"
    fi

    echo_verbose "generate metadata qr code"
    perform_qr_encoding "${CRRT_FILE}" "${CRRT_FILE}"

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
    for CRRT_QR_CODE in ${TMP_DIR}/*\.png; do
        CRRT_DESTINATION="$(basename ${CRRT_QR_CODE})"
        echo_verbose "move ${CRRT_QR_CODE} to ${CRRT_DESTINATION}"
        cp ${CRRT_QR_CODE} ${OUTPUT}/${CRRT_DESTINATION}
    done

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
}





# TODO: have a 'main' section where most of the actual
# work is done

assemble_into_A4(){

    local TMP_DIR=$(mktemp -d)
    echo_verbose "created working tmp: ${TMP_DIR}"
    cp -r ${FOLDER_NAME}/* ${TMP_DIR}/.
    echo "give time to copy otherwise decoding will fail"
    sleep 10

    local GENERAL_FOLDER_NAME=${FOLDER_NAME}
    FOLDER_NAME=${TMP_DIR}

    # Equivalent A4 paper dimensions in pixels at 300 DPI and 72 DPI respectively are: 2480 pixels x 3508 pixels (print resolution) 595 pixels x 842 pixels (screen resolution)
    # TODO: compute with logics, allow to adapt to dpi
    # TODO: make all of that happen in a tmp
    local A4_PIXELS_WIDTH=595
    local A4_PIXELS_HEIGHT=842

    local A4_LEFT_MARGIN=60
    local A4_RIGHT_MARGIN=${A4_LEFT_MARGIN}

    local A4_TOP_MARGIN=100
    local A4_BOTTOM_MARGIN=${A4_TOP_MARGIN}

    local A4_LINE_JUMP=100

    # TODO: all of this should be written in logics rather than hard coded

    # 1st page:
    # tile and a few written information
    # 1 QR code with layout information
    # the metadata QR code

    # layout information: left margin, inter-margin right-left, right margin,
    # line jump margin, top margin, bottom margin

    # 1st page ------------------------------
    convert -size ${A4_PIXELS_WIDTH}x${A4_TOP_MARGIN} xc:white ${FOLDER_NAME}/top_margin.png
    convert -size ${A4_PIXELS_WIDTH}x${A4_BOTTOM_MARGIN} xc:white ${FOLDER_NAME}/bottom_margin.png

    # text
    # 595 - 60 - 60
    local A4_TEXT_WIDTH=475
    local A4_TEXT_HEIGHT=250

    convert -size ${A4_LEFT_MARGIN}x${A4_TEXT_HEIGHT} xc:white ${FOLDER_NAME}/text_left_margin.png
    convert -size ${A4_RIGHT_MARGIN}x${A4_TEXT_HEIGHT} xc:white ${FOLDER_NAME}/text_right_margin.png

    # TODO: put relevant metadata here in plaintex
    # TODO: use automatic padding function to pad
    # TODO: force adding line breaks on the metadata to avoid cutting text.
    echo -n "text 15,15   \"" >> ${FOLDER_NAME}/text_1st_page.txt
    echo "some relevant metadata" >> ${FOLDER_NAME}/text_1st_page.txt
    # TODO: file name, date, how stored, number of pages
    echo -n "\"" >> ${FOLDER_NAME}/text_1st_page.txt

    convert -size ${A4_TEXT_WIDTH}x${A4_TEXT_HEIGHT} xc:white -font "FreeMono" -pointsize 14 -fill black -draw @${FOLDER_NAME}/text_1st_page.txt ${FOLDER_NAME}/text_1st_page.png

    convert ${FOLDER_NAME}/text_left_margin.png ${FOLDER_NAME}/text_1st_page.png ${FOLDER_NAME}/text_right_margin.png +append ${FOLDER_NAME}/text_image_chunk.png

    # put the layout qr code under
    touch ${FOLDER_NAME}/layout_metadata.txt
    echo "LEFT_MARGIN:${A4_LEFT_MARGIN}" >> ${FOLDER_NAME}/layout_metadata.txt
    echo "RIGHT_MARGIN:${A4_RIGHT_MARGIN}" >> ${FOLDER_NAME}/layout_metadata.txt
    echo "TOP_MARGIN:${A4_TOP_MARGIN}" >> ${FOLDER_NAME}/layout_metadata.txt
    echo "BOTTOM_MARGIN:${A4_BOTTOM_MARGIN}" >> ${FOLDER_NAME}/layout_metadata.txt

    perform_qr_encoding ${FOLDER_NAME}/layout_metadata.txt ${FOLDER_NAME}/layout_metadata
    
    local SIZE_Y_METADATA_LAYOUT=300

    pad_png_image ${FOLDER_NAME}/layout_metadata.png ${A4_PIXELS_WIDTH} ${SIZE_Y_METADATA_LAYOUT} ${FOLDER_NAME}/metadata_layout_padded.png

    local SIZE_Y_METADATA_DATA=$(( ${A4_PIXELS_HEIGHT} - ${A4_TEXT_HEIGHT} - ${SIZE_Y_METADATA_LAYOUT} ))

    pad_png_image ${FOLDER_NAME}/metadata.png ${A4_PIXELS_WIDTH} ${SIZE_Y_METADATA_DATA} ${FOLDER_NAME}/metadata_data_padded.png

    convert ${FOLDER_NAME}/text_1st_page.png ${FOLDER_NAME}/metadata_layout_padded.png ${FOLDER_NAME}/metadata_data_padded.png -append ${FOLDER_NAME}/first_page_full.png

    # on all pages: use a fixed layout corresponding to the max number of bytes ie max size of the qr codes
    # TODO: make it adaptive; currently it is hard coded following the choice of bytes per qr-code

    # pad to a slightly larger size; this is hard coded, consider to fix?
    for CRRT_FILE in ${FOLDER_NAME}/data-??.png; do
        local BASE_NAME=$(basename ${CRRT_FILE})
        pad_png_image ${CRRT_FILE} 269 269 ${FOLDER_NAME}/padded_${BASE_NAME}
    done

    # glue together 2 and 2 images to create a banner
    local LIST_PADDED_QR_DATA=$(ls ${FOLDER_NAME}/padded_data-??.png | tr '\r\n' ' ')
    create_banner_of_qr_codes 1 ${FOLDER_NAME} ${LIST_PADDED_QR_DATA}

    # glue together banners to create pages
    local LIST_BANNER_QR_DATA=$(ls ${FOLDER_NAME}/banner_*\.png | tr '\r\n' ' ')
    create_page_of_qr_banners 1 ${FOLDER_NAME} ${LIST_BANNER_QR_DATA}

    # put all the pages together
    img2pdf --pagesize A4 -o ${FOLDER_NAME}/full_layout_QR_dump.pdf ${FOLDER_NAME}/first_page_full.png ${FOLDER_NAME}/data_page_*.png

    sleep 1

    cp ${FOLDER_NAME}/full_layout_QR_dump.pdf ${OUTPUT}
    FOLDER_NAME=${GENERAL_FOLDER_NAME}
    rm -rf ${TMP_DIR}
}


read_pdf_A4(){
    
    echo_verbose "start to read PDF A4 ${FILE_NAME}"

    local BASE_FOLDER=$(dirname "${FILE_NAME}")

    # to all these operations in a tmp folder
    local TMP_DIR=$(mktemp -d)
    echo_verbose "created working tmp: ${TMP_DIR}"
    cp -r ${BASE_FOLDER}/* ${TMP_DIR}/.
    echo "give time to copy otherwise decoding will fail"
    sleep 10

    local GENERAL_FOLDER_NAME=${BASE_FOLDER}
    BASE_FOLDER=${TMP_DIR}

    # split pages
    convert -density 72 ${FILE_NAME} ${BASE_FOLDER}/extracted_A4_page_%04d.png

    # for ease, rename the metadata page
    mv ${BASE_FOLDER}/extracted_A4_page_0000.png ${BASE_FOLDER}/extracted_A4_metadata.png

    # first metadata: QR-code about layout, Qr-code about metadata
    # TODO: info about how to cut to extract the metadata
    # TODO: info about number of pages, number of qr data codes, etc
    convert "${BASE_FOLDER}/extracted_A4_metadata.png[475x250+0+0]" ${BASE_FOLDER}/extracted_text.png
    convert "${BASE_FOLDER}/extracted_A4_metadata.png[595x300+0+250]" ${BASE_FOLDER}/extracted_layout_metadata.png
    convert "${BASE_FOLDER}/extracted_A4_metadata.png[595x292+0+550]" ${BASE_FOLDER}/metadata.png

    # then the data pages
    extract_QR_codes_from_pages ${BASE_FOLDER}

    # clean over numerous empty QR codes
    # TODO: do this clearly from metadata, this is a hack
    echo_verbose "testing for empty restored qr codes"

    for CRRT_QR_CODE in ${BASE_FOLDER}/data-??.png
    do
        show_debug_variable "CRRT_QR_CODE"

        local IS_EMPTY=$(identify -format "%[fx:(mean==1)?1:0]" ${CRRT_QR_CODE})
        show_debug_variable "IS_EMPTY"

        if [[ ${IS_EMPTY} = "0" ]]
        then
            echo_verbose "non empty qr code"
        else
            echo_verbose "empty qr code, delete"
            rm ${CRRT_QR_CODE}
        fi
    done

    cp ${BASE_FOLDER}/extracted_layout_metadata.png ${OUTPUT}
    cp ${BASE_FOLDER}/metadata.png ${OUTPUT}
    cp ${BASE_FOLDER}/data-*.png ${OUTPUT}
    BASE_FOLDER=${GENERAL_FOLDER_NAME}
    rm -rf ${TMP_DIR}
}



##############################################
# decoding                                   #
##############################################

# TODO: split logics to make it easier to decode from a
# messy set of QR-codes

# for now takes a folder as argument and decode stuff there
# assert that the folder contains all the qr-codes with names
# in the format:
# metadata.png
# data-XX.png
full_decode(){
    # NOTE: this works now because the original files were in the tmp dict at encoding...
    # TODO: do all intermediate operations in a tmp

    # to all these operations in a tmp folder
    local TMP_DIR=$(mktemp -d)
    echo_verbose "created working tmp: ${TMP_DIR}"
    cp -r ${FOLDER_NAME}/* ${TMP_DIR}/.
    echo "give time to copy otherwise decoding will fail"
    sleep 10

    local GENERAL_FOLDER_NAME=${FOLDER_NAME}
    FOLDER_NAME=${TMP_DIR}

    # decode metadata
    local TO_DECODE="${FOLDER_NAME}/metadata.png"
    local DESTINATION="${FOLDER_NAME}/metadata"

    # TODO: check that filename exists

    perform_qr_decoding ${TO_DECODE} ${DESTINATION}
    # TODO: extract information from the metadata to help the following

    # decode all segments
    for CRRT_QR_CODE in ${FOLDER_NAME}/data-??.png
    do
        local CRRT_DESTINATION="${CRRT_QR_CODE%.*}"
        echo_verbose $CRRT_QR_CODE
        echo_verbose $CRRT_DESTINATION
        perform_qr_decoding "${CRRT_QR_CODE}" "${CRRT_DESTINATION}"

    done

    # read the metadata
    # TODO: move to a function
    # NOTE: had tried but encountered problems, probably something stupid
    local METADATA_PATH=${FOLDER_NAME}/metadata
    local IFS=":"
    # TODO: fix uppper case convention in this loop
    while read -r name value
    do
        echo $name
        # special treatment when debug display in case of binary data
        if [[ "${name}" = "ID" ]]
        then
            if [[ "${VERBOSE}" = "True" ]]
            then
                echo -n ${value} | xxd
            fi
        else
            echo_verbose "Content of metadata field ${name} is ${value}"
        fi
        declare "${name}"="${value}"
    done < ${METADATA_PATH}

    # TODO: fix this messy thing under with file names and paths
    # assemble the final data file
    #local OUTPUT_NAME="${QRD}"
    local OUTPUT_FILE="${FOLDER_NAME}/${QRD}"
    local ASSEMBLED_COMPRESSED="${FOLDER_NAME}/compressed.gz"
    local ASSEMBLED_UNCOMPRESSED="${FOLDER_NAME}/compressed"

    show_debug_variable "OUTPUT_FILE"
    show_debug_variable "ASSEMBLED_COMPRESSED"

    #echo_verbose "using output file ${OUTPUT_FILE}"
    #touch ${OUTPUT_FILE}
    touch ${ASSEMBLED_COMPRESSED}

    # TODO: use the metadata to check consistency, digests, etc
    # TODO: have a digest of the whole file
    for CRRT_DATA in ${FOLDER_NAME}/data-??
    do
	# the data part
        cat ${CRRT_DATA} >> ${ASSEMBLED_COMPRESSED}
        # remove the last bytes that are metadata
        # TODO: put this in logics
        truncate -s -${SIZE_DATAQR_METADATA} ${ASSEMBLED_COMPRESSED}

        # the metadata part
        # TODO FIXME: some warnings here because of null bytes
        # possible solution: use rev and truncate
        local CRRT_METADATA="${CRRT_DATA}_meta"
        n_last_bytes "${SIZE_DATAQR_METADATA}" "${CRRT_DATA}" "${CRRT_METADATA}"

        # TODO: make all of this with arithmetics
        # TODO: build an external function to do this in 1 single pass
        local FILE_CRRT_DIGEST="${CRRT_METADATA}_digest"
        dd if="${CRRT_METADATA}" of="${FILE_CRRT_DIGEST}" skip=0 count=20 iflag=skip_bytes,count_bytes status=none
        show_debug_file_binary "FILE_CRRT_DIGEST"

        local FILE_CRRT_ID="${CRRT_METADATA}_ID"
        dd if="${CRRT_METADATA}" of="${FILE_CRRT_ID}" skip=20 count=8 iflag=skip_bytes,count_bytes status=none
        show_debug_file_binary "FILE_CRRT_ID"

        local FILE_CRRT_RANK="${CRRT_METADATA}_RANK"
        dd if="${CRRT_METADATA}" of="${FILE_CRRT_RANK}" skip=28 count=2 iflag=skip_bytes,count_bytes status=none
        show_debug_file_binary "FILE_CRRT_RANK"

        # TODO: make robust checks
        # check that order of the segments corresponds
        # check that Id corresponds
        # check that digest corresponds
        # check the metadata
    done
    
    gunzip ${ASSEMBLED_COMPRESSED}
    mv ${ASSEMBLED_UNCOMPRESSED} ${OUTPUT_FILE}

    echo_verbose "success with gunzip"

    cp ${OUTPUT_FILE} ${OUTPUT}
    FOLDER_NAME=${GENERAL_FOLDER_NAME}
    rm -rf ${TMP_DIR}
}



# TODO: function to layout on A4 page
# - human readable title and info
# - metadata qr
# - data qr

# TODO: function to extract list of QRs given a scan or series of scans
# - find metatada QR
# - decide how the QRs to extract should look like
# - get the QRs from the A4 and make ready to use the extraction function






##############################################
# actually do the work                       #
##############################################

if [[ "${ACTION}" = "Encode" ]]
then
    echo_verbose "doing an encoding"
    full_encode
fi


if [[ "${ACTION}" = "Decode" ]]
then
    echo_verbose "doing a decoding"
    full_decode
fi

if [[ "${ACTION}" = "Layout" ]]
then
    echo_verbose "doing a A4 layout of a dump"
    assemble_into_A4
fi

if [[ "${ACTION}" = "ReadPDF" ]]
then
    echo_verbose "Extracting the QR codes of a PDF dump"
    read_pdf_A4
fi
