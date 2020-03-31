#!/bin/bash

source ./boilerplate.sh
source ./tools.sh
source ./qrdump_params.sh --no-print

full_encode(){
    echo_verbose "----------------------------------------"
    echo_verbose "entering function full_encode"

    local INPUT=$1
    local OUTPUT=$2

    # generate a random signature ID for the package
    # alphanumeric with numbers to keep things easy (binary introduces challenges with null bytes etc)
    local ID=$(dd if=/dev/urandom  bs=512 count=1 status=none | tr -dc 'a-zA-Z0-9' | fold -w ${QRDUMP_SIZE_ID} | head -n 1)
    show_debug_variable ID

    # create temporary folder
    local TMP_DIR=$(mktemp -d)
    show_debug_variable TMP_DIR

    # compress the destination file
    gzip -vc9 -q -qq ${INPUT} > ${TMP_DIR}/compressed.gz

    # split the compressed file
    # into segments to be used for qr-codes.
    split -d -a 6 -b ${QRDUMP_CONTENT_QR_CODE_BYTES} ${TMP_DIR}/compressed.gz ${TMP_DIR}/data-

    local NBR_DATA_SEGMENTS=$(find ${TMP_DIR} -name 'data-*' | wc -l)
    echo_verbose "split into ${NBR_DATA_SEGMENTS} segments"

    # append for each data segment
    # the ID, and current segment number
    # NOTE: took away using the digest; consider re-introducing but then CAREFUL of null bytes...
    local COUNTER=0

    for CRRT_FILE in ${TMP_DIR}/data-*; do
        echo -n "${ID}" >> ${CRRT_FILE}

        printf "0: %.4x" $COUNTER | xxd -r -g0 >> ${CRRT_FILE}
        local COUNTER=$((COUNTER+1))
    done

    # generate the data segments qr codes
    for CRRT_FILE in ${TMP_DIR}/data-*; do
        perform_qr_encoding "${CRRT_FILE}" "${CRRT_FILE}"
    done

    # generate the qr code with the metadata
    echo_verbose "create metadata"

    local CRRT_FILE=${TMP_DIR}/metadata
    echo -n "QRD:" >> ${CRRT_FILE}
    echo "$(basename ${INPUT})" >> ${CRRT_FILE}

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
    if [[ "$(stat --printf="%s" ${CRRT_FILE})" -gt ${QRDUMP_MAX_QR_SIZE} ]]; then
        echo_verbose "*** WARNING *** looks like the metadata is dangerously big!"
    fi

    perform_qr_encoding "${CRRT_FILE}" "${CRRT_FILE}"

    # move all the qr codes to a new folder
    # at the current location
    for CRRT_QR_CODE in ${TMP_DIR}/*\.png; do
        CRRT_DESTINATION="$(basename ${CRRT_QR_CODE})"
        echo_verbose "move ${CRRT_QR_CODE} to ${CRRT_DESTINATION}"
        cp ${CRRT_QR_CODE} ${OUTPUT}/${CRRT_DESTINATION}
        sync
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
}
