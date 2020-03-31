#!/bin/bash

CWD="$(pwd)/"

##############################################
# parse incoming args                        #
##############################################

! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

# TODO: implement the c and r

# acceptable options
OPTIONS=hvabg:edro:csi:lt
LONGOPTS=help,verbose,base64,debug,digest:,encode,decode,read-A4,output:,create-A4,safe-mode,input:,layout,extract

# default values of the options
# TODO: follow QRDUMP_ naming convention for global vars
HELP="False"
VERBOSE="False"
ENCODING="binary"
DEBUG="False"
DIGEST="sha1sum"
ACTION="None"
INPUT="None"
OUTPUT="None"
SAFE_MODE="None"

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi

eval set -- "$PARSED"

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -h|--help)
            HELP="True"; shift;;
        -v|--verbose)
            VERBOSE="True"; shift;;
        -a|--base64)
            ENCODING="base64"; shift;;
        -b|--debug)
            DEBUG="True"; VERBOSE=True; shift;;
        -g|--digest)
            DIGEST="$2"; shift 2;;
        -e|--encode)
            ACTION="Encode"; shift;;
        -d|--decode)
            ACTION="Decode"; shift;;
        -r|--read-A4)
            ACTION="ReadA4"; shift;;
        -o|--output)
            OUTPUT="$2"; shift 2;;
        -c|--create-A4)
            ACTION="CreateA4";shift;;
        -s|--safe-mode)
            SAFE_MODE="True"; shift;;
        -i|--input)
            INPUT="$2"; shift 2;;
        -l|--layout)
            ACTION="Layout"; shift;;
        -t|--extract)
            ACTION="Extract"; shift;;
        --)
            shift; break;;
        *)
            echo "Invalid args; type -h or --help for help"; exit 3;;
    esac
done


##############################################
# now ready to import functions etc          #
##############################################

# NOTE: this is not done earlier because need to decide
# some of the params (in particular debug et co params)
source ./tools.sh
source ./qrdump_params.sh
source ./full_encode.sh
source ./full_decode.sh
source ./create_A4.sh
source ./ReadA4.sh


##############################################
# in case of debug, show the options         #
##############################################

echo_verbose " "
echo_verbose "----------------------------------------"
echo_verbose "show parsed input"
show_debug_variable "HELP"
show_debug_variable "VERBOSE"
show_debug_variable "ENCODING"
show_debug_variable "DEBUG"
show_debug_variable "DIGEST"
show_debug_variable "ACTION"
show_debug_variable "INPUT"
show_debug_variable "OUTPUT"
show_debug_variable "SAFE_MODE"
show_debug_variable "CWD"
echo_verbose "----------------------------------------"
echo_verbose " "

##############################################
# input sanitation                           #
##############################################

# check using base64 for now
if [[ "${ENCODING}" != "base64" ]]
then
    echo "at the moment, only base64 encoding is supported!"
    echo "see: https://stackoverflow.com/questions/60506222"
    echo "Aborting..."
    exit 1
fi

##############################################
# call the right command                     #
##############################################

if [ "$HELP" = "True" ]; then
    echo "TODO help"
    exit 0
fi

INPUT="${CWD}${INPUT}"
OUTPUT="${CWD}${OUTPUT}"

case "$ACTION" in
    None)
        echo "no action chosen! Abort."; exit 1;;
    Encode)
        echo_verbose "execute encode"
        assert_set INPUT
        assert_set OUTPUT
        assert_file_or_folder_exists INPUT
        assert_avail_folder OUTPUT
        full_encode $INPUT $OUTPUT
        ;;
    Decode)
        echo_verbose "execute decode"
        assert_set INPUT
        assert_set OUTPUT
        assert_avail_folder INPUT
        assert_avail_folder OUTPUT
        full_decode $INPUT $OUTPUT
        ;;
    Layout)
        echo_verbose "execute layout"
        assert_set INPUT
        assert_set OUTPUT
        assert_avail_folder INPUT
        assert_avail_file_destination OUTPUT
        assemble_into_A4 $INPUT $OUTPUT
        ;;
    Extract)
        echo_verbose "execute extract"
        assert_set INPUT
        assert_set OUTPUT
        assert_avail_file INPUT
        assert_avail_folder OUTPUT
        extract_all_QR_codes $INPUT $OUTPUT
        ;;
    CreateA4)
        echo_verbose "execute create A4"
        assert_set INPUT
        assert_set OUTPUT
        assert_file_or_folder_exists INPUT
        assert_avail_file_destination OUTPUT
        WORKING_DIR=$(mktemp -d)
        full_encode $INPUT $WORKING_DIR
        assemble_into_A4 $WORKING_DIR $OUTPUT
        rm -rf WORKING_DIR
        ;;
    ReadA4)
        echo_verbose "execute read pdf"
        assert_set INPUT
        assert_set OUTPUT
        assert_file_or_folder_exists INPUT
        assert_avail_folder OUTPUT
        WORKING_DIR=$(mktemp -d)
        extract_all_QR_codes $INPUT $WORKING_DIR
        full_decode $WORKING_DIR $OUTPUT
        ;;
esac
