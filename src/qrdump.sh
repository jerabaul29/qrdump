#!/bin/bash

CWD="$(pwd)/"

QRDUMP_SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $QRDUMP_SCRIPTPATH

##############################################
# check needed packages                      #
##############################################

source ./check_dependencies.sh

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
OPTIONS=hvabg:edro:csi:ltm:p
LONGOPTS=help,verbose,base64,debug,digest:,encode,decode,read-A4,output:,create-A4,safe-mode,input:,layout,extract,version,metadata:,parchive,manual,allow-whitespace

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
SAFE_MODE="False"
QRDUMP_METADATA=""
QRDUMP_PARCHIVE="False"
QRDUMP_MANUAL="False"
QRDUMP_ALLOW_WHITESPACE="False"
QRDUMP_VERSION="0.0"
QRDUMP_CORE_FILE="None"

if [ $# -eq 0 ]; then
    echo "no argument, displaying help..."
    HELP="True"
fi

! PARSED="$(getopt --options="$OPTIONS" --longoptions="$LONGOPTS" --name "$0" -- "$@")"
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
            DEBUG="True"; VERBOSE="True"; shift;;
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
        --version)
            ACTION="Version"; shift;;
        -m|--metadata)
            QRDUMP_METADATA="$2"; shift 2;;
        -p|--parchive)
            QRDUMP_PARCHIVE="True"; shift;;
        --manual)
            QRDUMP_MANUAL="True"; shift;;
        --allow-whitespace)
            QRDUMP_ALLOW_WHITESPACE="True"; shift;;
        --)
            shift; break;;
        *)
            echo "Invalid args; type -h or --help for help"; exit 3;;
    esac
done

if [ "$HELP" = "True" ]; then
    echo -e "$(cat help.txt)"
    exit 0
fi

if [ "$QRDUMP_MANUAL" = "True" ]; then
    echo -e "$(cat manual.txt)"
    exit 0
fi

if [ "$ACTION" = "Version" ]; then
    echo "v${QRDUMP_VERSION}"
    exit 0
fi

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

INPUT="$(expand_full_relative_path "${CWD}" "${INPUT}")"
OUTPUT="$(expand_full_relative_path "${CWD}" "${OUTPUT}")"

detect_space INPUT
detect_space OUTPUT

QRDUMP_ORIGINAL_INPUT="$(basename ${INPUT})"

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
show_debug_variable "QRDUMP_PARCHIVE"
echo_verbose "----------------------------------------"
echo_verbose " "

##############################################
# input sanitation                           #
##############################################

# check using base64 for now
if [[ "${ENCODING}" != "base64" ]]; then

    ZBARIMG_VERSION="$(zbarimg --version)"
    dpkg --compare-versions "${ZBARIMG_VERSION}" "ge" "0.23"

    if [[ "$?" != "0" ]]; then
        echo "for zbar versions lower than 0.23.1, only base64 encoding is supported!"
        echo "see: https://stackoverflow.com/questions/60506222"
        echo "Aborting..."
        exit 1
    fi
fi

# safe mode is only offered to pdf for now
if [[ "$SAFE_MODE" = "True" ]]; then
    if [[ ! "$ACTION" = "CreateA4" ]]; then
        echo "for now safe mode is only possible with --create-A4"
        exit 1
    fi
fi

if [[ "${ACTION}" = "CreateA4" ]]; then
    if [[ "${SAFE_MODE}" = "False" ]]; then
        echo "WARNING: running a create-A4 without --safe-mode"
    fi
fi

if [[ "$QRDUMP_PARCHIVE" = "True" ]]; then
    if [[ ! "$ACTION" =~ ^(ReadA4|CreateA4) ]]; then
        echo "--parchive is only possible with --create-A4 or --read-A4"
        exit 1
    fi
fi

# only support files as input; the user should zip himself if want to use on folder
if [[ "${ACTION}" =~ ^(Encode|CreateA4)$ ]]; then
    if [ ! -f $INPUT ]; then
        echo "using INPUT: $INPUT"
        echo "a file is needed as input"
        exit 1
    fi
fi

if [ ! "$QRDUMP_METADATA" = "" ]; then
    if [[ ! "${ACTION}" =~ ^(Layout|CreateA4)$ ]]; then
        echo "using metadata, but:"
        echo "metadata is used only for writing on the pdfs at creation"
        exit 1
    fi
else
    if [[ "${ACTION}" =~ ^(Layout|CreateA4)$ ]]; then
        echo "WARNING: metadata not set, using the defaul 'NO MSG' metadata"
        QRDUMP_METADATA="NO MSG"
    fi
fi

if [[ "${ACTION}" =~ ^(CreateA4|ReadA4)$ ]]; then
    if [[ "${QRDUMP_PARCHIVE}" = "False" ]]; then
        echo "$INPUT"
        if [[ ! "${INPUT: -5}" == ".par2" ]]; then
            echo "WARNING: no --parchive dumping; this is recommended to allow robustness"
        fi
    fi
fi

##############################################
# call the right command                     #
##############################################

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
        sha512sum "$INPUT" >> "$OUTPUT/sha512sum.meta"
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
        assemble_into_A4 $INPUT $OUTPUT "$QRDUMP_METADATA"
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
        WORKING_DIR="$(mktemp -d)"
        full_encode $INPUT $WORKING_DIR
        sha512sum "$INPUT" >> "$WORKING_DIR/sha512sum.meta"
        assemble_into_A4 $WORKING_DIR $OUTPUT "$QRDUMP_METADATA"

        if [[ "$SAFE_MODE" = "True" ]]; then
            echo_verbose "checking that safe to extract"
            TMP_OUT="$(mktemp -d)/"
            WORKING_DIR_2="$(mktemp -d)"
            extract_all_QR_codes $OUTPUT $WORKING_DIR_2
            full_decode $WORKING_DIR_2 $TMP_OUT
            assert_identical $INPUT $TMP_OUT/$(basename $INPUT)
            rm -rf $WORKING_DIR_2
            rm -rf TMP_OUT
        fi
        rm -rf $WORKING_DIR

        if [[ "$QRDUMP_PARCHIVE" = "True" ]]; then
            echo ""
            echo -n "NOTE: now encoding parchive info"
            WORKING_DIR_2="$(mktemp -d)"
            echo_verbose "doing a parchive dump"
            cp "${INPUT}" "${WORKING_DIR_2}/"
            par2 create -qq -s${QRDUMP_PARCHIVE_SIZE} -r${QRDUMP_PARCHIVE_REDUNDANCY} "${WORKING_DIR_2}/$(basename ${INPUT})"

            for CRRT_PAR2 in ${WORKING_DIR_2}/*\.par2; do
                CRRT_PDF_NAME="${WORKING_DIR_2}/$(basename ${CRRT_PAR2}).pdf"
                QRDUMP_GLOBAL_OUTPUT="$(dirname ${OUTPUT})"

                (bash ./qrdump.sh --base64 --create-A4 --safe-mode --input "${CRRT_PAR2}" --output "${CRRT_PDF_NAME}" --metadata "parchive dump for error correction of main dump")&
                wait $!

                mv "${CRRT_PDF_NAME}" "${QRDUMP_GLOBAL_OUTPUT}/$(basename ${OUTPUT}).$(basename ${CRRT_PDF_NAME})"
            done

            rm -rf $WORKING_DIR_2
        fi
        ;;
    ReadA4)
        echo_verbose "execute read pdf"
        assert_set INPUT
        assert_set OUTPUT
        assert_file_or_folder_exists INPUT
        assert_avail_folder OUTPUT
        WORKING_DIR="$(mktemp -d)"
        echo_verbose "created tmp dir"

        extract_all_QR_codes $INPUT $WORKING_DIR
        full_decode $WORKING_DIR $OUTPUT

        rm -rf $WORKING_DIR

        if [[ "$QRDUMP_PARCHIVE" = "True" ]]; then
            for CRRT_PAR2_ARCHIVE in ${INPUT}*\.par2\.pdf; do
                WORKING_DIR="$(mktemp -d)"

                extract_all_QR_codes $CRRT_PAR2_ARCHIVE $WORKING_DIR
                full_decode $WORKING_DIR $OUTPUT
                rm -rf $WORKING_DIR
            done

            if [[ "${QRDUMP_CORE_FILE}" = "None" ]]; then
                echo "problem attempting to par2 verify; no qrdump core file"
                exit 1
            else
                par2 verify "${OUTPUT}/${QRDUMP_CORE_FILE}"
            fi
        fi
        ;;
esac

cd $CWD
