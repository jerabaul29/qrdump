#!/bin/bash

source ./boilerplate.sh
source ./tools.sh
source ./qrdump_params.sh --no-print

full_decode(){
    echo_verbose "----------------------------------------"
    echo_verbose "entering function full_decode"

    local INPUT="$1"
    local OUTPUT="$2"

    # to all these operations in a tmp folder
    local TMP_DIR="$(mktemp -d)"

    cp ${INPUT}/*\.png ${TMP_DIR}/.
    sync

    # decode metadata
    local TO_DECODE="${TMP_DIR}/metadata.png"
    local DESTINATION="${TMP_DIR}/metadata.dat"

    echo_verbose "decode metadata png"
    perform_qr_decoding ${TO_DECODE} ${DESTINATION}

    # decode all segments
    for CRRT_QR_CODE in ${TMP_DIR}/data-*.png
    do
        echo_verbose "decode $CRRT_QR_CODE"
        local CRRT_DESTINATION="${CRRT_QR_CODE%.*}.dat"
        perform_qr_decoding "${CRRT_QR_CODE}" "${CRRT_DESTINATION}"
    done

    echo_verbose "done reading all"

    # read the metadata
    # TODO: move to a function
    # NOTE: had tried but encountered problems, probably something stupid
    local METADATA_PATH="${TMP_DIR}/metadata.dat"
    local IFS=":"

    while read -r NAME VALUE
    do
        if [[ "${NAME}" = "ID" ]]
        then
            echo_verbose "metadata ${NAME} is ${VALUE}"
        fi
        declare local "${NAME}"="${VALUE}"
    done < ${METADATA_PATH}

    # TODO: fix this messy thing under with file names and paths
    # assemble the final data file
    #local OUTPUT_NAME="${QRD}"
    local OUTPUT_FILE="${TMP_DIR}/${QRD}"
    local ASSEMBLED_COMPRESSED="${TMP_DIR}/compressed.gz"
    local ASSEMBLED_UNCOMPRESSED="${TMP_DIR}/compressed"

    touch ${ASSEMBLED_COMPRESSED}

    # TODO: use the metadata to check consistency, digests, etc
    # TODO: have a digest of the whole file
    for CRRT_DATA in ${TMP_DIR}/data-*\.dat
    do
        # the data part
        cat ${CRRT_DATA} >> ${ASSEMBLED_COMPRESSED}
        # remove the last bytes that are metadata
        # TODO: put this in logics
        truncate -s -${QRDUMP_SIZE_DATAQR_METADATA} ${ASSEMBLED_COMPRESSED}

        # the metadata part
        # TODO FIXME: some warnings here because of null bytes
        # possible solution: use rev and truncate
        local CRRT_METADATA="${CRRT_DATA}_meta"
        n_last_bytes "${QRDUMP_SIZE_DATAQR_METADATA}" "${CRRT_DATA}" "${CRRT_METADATA}"

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
    sync
    rm -rf ${TMP_DIR}
}
