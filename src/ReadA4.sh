source ./boilerplate.sh
source ./qrdump_params.sh --no-print
source ./tools.sh

extract_QR_codes_from_pages(){
    local BASE_FOLDER="$1"

    local CRRT_QR_CODE_NBR=0

    for CRRT_PAGE in ${BASE_FOLDER}/extracted_A4_page_*\.png
    do
        # split the QR codes
        show_debug_variable "CRRT_PAGE"

        # first banner
        convert "${CRRT_PAGE}[297x269+0+32]" ${BASE_FOLDER}/data-$(int_with_5_digits ${CRRT_QR_CODE_NBR}).png &> /dev/null
        CRRT_QR_CODE_NBR="$(( ${CRRT_QR_CODE_NBR} + 1  ))"
        convert "${CRRT_PAGE}[297x269+297+32]" ${BASE_FOLDER}/data-$(int_with_5_digits ${CRRT_QR_CODE_NBR}).png &> /dev/null
        CRRT_QR_CODE_NBR="$(( ${CRRT_QR_CODE_NBR} + 1  ))"

        # second banner
        convert "${CRRT_PAGE}[297x269+0+302]" ${BASE_FOLDER}/data-$(int_with_5_digits ${CRRT_QR_CODE_NBR}).png &> /dev/null
        CRRT_QR_CODE_NBR="$(( ${CRRT_QR_CODE_NBR} + 1  ))"
        convert "${CRRT_PAGE}[297x269+297+302]" ${BASE_FOLDER}/data-$(int_with_5_digits ${CRRT_QR_CODE_NBR}).png &> /dev/null
        CRRT_QR_CODE_NBR="$(( ${CRRT_QR_CODE_NBR} + 1  ))"

        # third banner
        convert "${CRRT_PAGE}[297x269+0+572]" ${BASE_FOLDER}/data-$(int_with_5_digits ${CRRT_QR_CODE_NBR}).png &> /dev/null
        CRRT_QR_CODE_NBR="$(( ${CRRT_QR_CODE_NBR} + 1  ))"
        convert "${CRRT_PAGE}[297x269+297+572]" ${BASE_FOLDER}/data-$(int_with_5_digits ${CRRT_QR_CODE_NBR}).png &> /dev/null
        CRRT_QR_CODE_NBR="$(( ${CRRT_QR_CODE_NBR} + 1  ))"
    done
}

extract_all_QR_codes(){
    local INPUT="$1"
    local OUTPUT="$2"

    # split pages
    echo_verbose "split pages"
    convert -density 72 ${INPUT} ${OUTPUT}/extracted_A4_page_%04d.png

    # for ease, rename the metadata page
    echo_verbose "rename metadata page"
    mv ${OUTPUT}/extracted_A4_page_0000.png ${OUTPUT}/extracted_A4_metadata.png

    # first metadata: QR-code about layout, Qr-code about metadata
    # TODO: do something with this
    echo_verbose "convert to null"
    convert "${OUTPUT}/extracted_A4_metadata.png[475x250+0+0]" ${OUTPUT}/extracted_text.png &> /dev/null
    convert "${OUTPUT}/extracted_A4_metadata.png[595x300+0+250]" ${OUTPUT}/extracted_layout_metadata.png &> /dev/null
    convert "${OUTPUT}/extracted_A4_metadata.png[595x292+0+550]" ${OUTPUT}/metadata.png &> /dev/null

    # then the data pages
    echo_verbose "extract data pages"
    extract_QR_codes_from_pages ${OUTPUT}

    # clean over numerous empty QR codes
    echo_verbose "testing for empty restored qr codes"

    for CRRT_QR_CODE in ${OUTPUT}/data-*.png
    do
        local IS_EMPTY="$(identify -format "%[fx:(mean==1)?1:0]" ${CRRT_QR_CODE})"

        if [[ ${IS_EMPTY} = "0" ]]
        then
            :
        else
            rm ${CRRT_QR_CODE}
        fi
    done

    rm ${OUTPUT}/extracted_A4_*\.png
}
