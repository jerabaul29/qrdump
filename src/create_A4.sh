#!/bin/bash

source ./boilerplate.sh
source ./qrdump_params.sh --no-print

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

    local ADD_RIGHT=$(( (${FINAL_X_SIZE}-${CRRT_PNG_X_SIZE}) / 2 ))
    local ADD_LEFT=$(( ${FINAL_X_SIZE} - ${CRRT_PNG_X_SIZE} - ${ADD_RIGHT}  ))

    local ADD_TOP=$(( (${FINAL_Y_SIZE} - ${CRRT_PNG_Y_SIZE}) / 2 ))
    local ADD_BOTTOM=$(( ${FINAL_Y_SIZE} - ${CRRT_PNG_Y_SIZE} - ${ADD_TOP} ))

    convert -size ${ADD_LEFT}x${CRRT_PNG_Y_SIZE} xc:white ${BASE_FOLDER}/left_margin.png
    convert -size ${ADD_RIGHT}x${CRRT_PNG_Y_SIZE} xc:white ${BASE_FOLDER}/right_margin.png

    convert ${BASE_FOLDER}/left_margin.png ${PNG_IN} ${BASE_FOLDER}/right_margin.png +append ${BASE_FOLDER}/padded_left_right.png

    convert -size ${FINAL_X_SIZE}x${ADD_TOP} xc:white ${BASE_FOLDER}/top_margin.png
    convert -size ${FINAL_X_SIZE}x${ADD_BOTTOM} xc:white ${BASE_FOLDER}/bottom_margin.png

    convert ${BASE_FOLDER}/top_margin.png ${BASE_FOLDER}/padded_left_right.png ${BASE_FOLDER}/bottom_margin.png -append ${PNG_OUT}
}

create_banner_of_qr_codes(){
    # arguments:
    # - banner number
    # - folder name
    # - then the list of things to use for the banner

    # check that at least 3 args (ie the first 2 + at least 1 data qr code)
    if [ "$#" -lt 3 ]
    then
        echo "too few arguments to generate a banner!"
        exit 1
    fi

    local BANNER_NUMBER=$1
    local BANNER_NUMBER_REPR=$(int_with_5_digits $BANNER_NUMBER )
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

    convert ${FOLDER_NAME}/padding_banner_sides.png ${FIRST_DATA_TO_USE} ${FOLDER_NAME}/padding_banner_middle.png ${SECOND_DATA_TO_USE} ${FOLDER_NAME}/padding_banner_sides.png +append ${FOLDER_NAME}/banner_${BANNER_NUMBER_REPR}.png

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
    local PAGE_NUMBER_REPR=$(int_with_5_digits $PAGE_NUMBER)
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
    echo "PAGE ${PAGE_NUMBER_REPR}; some relevant metadata" >> ${FOLDER_NAME}/text_top.txt
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
        ${FOLDER_NAME}/data_page_${PAGE_NUMBER_REPR}.png

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

int_with_5_digits(){
    local padded=$1
    local cleaned=${padded##+(0)}
    printf "%05d\n" $(( 10#$cleaned ))
}

int_with_2_digits(){
    local padded=$1
    local cleaned=${padded##+(0)}
    printf "%02d\n" $cleaned
}

assemble_into_A4(){
    local INPUT=$1
    local OUTPUT=$2

    local TMP_DIR=$(mktemp -d)
    cp -r ${INPUT}/* ${TMP_DIR}/.
    sync

    convert -size ${QRDUMP_A4_PIXELS_WIDTH}x${QRDUMP_A4_TOP_MARGIN} xc:white ${TMP_DIR}/top_margin.png
    convert -size ${QRDUMP_A4_PIXELS_WIDTH}x${QRDUMP_A4_BOTTOM_MARGIN} xc:white ${TMP_DIR}/bottom_margin.png
    convert -size ${QRDUMP_A4_LEFT_MARGIN}x${QRDUMP_A4_TEXT_HEIGHT} xc:white ${TMP_DIR}/text_left_margin.png
    convert -size ${QRDUMP_A4_RIGHT_MARGIN}x${QRDUMP_A4_TEXT_HEIGHT} xc:white ${TMP_DIR}/text_right_margin.png

    # 1st page: contain the metadata ----- ------------------------------
    # tile and a few written information
    # 1 QR code with layout information
    # the metadata QR code

    # metadata text
    # TODO: put relevant metadata here in plaintex
    # TODO: use automatic padding function to pad
    # TODO: force adding line breaks on the metadata to avoid cutting text.
    echo -n "text 15,15   \"" >> ${TMP_DIR}/text_1st_page.txt
    # this is the metadata that will be displayed
    echo "some relevant metadata" >> ${TMP_DIR}/text_1st_page.txt
    # TODO: file name, date, how stored, number of pages
    echo -n "\"" >> ${TMP_DIR}/text_1st_page.txt

    convert -size ${QRDUMP_A4_TEXT_WIDTH}x${QRDUMP_A4_TEXT_HEIGHT} xc:white -font "FreeMono" -pointsize 14 -fill black -draw @${TMP_DIR}/text_1st_page.txt ${TMP_DIR}/text_1st_page.png

    convert ${TMP_DIR}/text_left_margin.png ${TMP_DIR}/text_1st_page.png ${TMP_DIR}/text_right_margin.png +append ${TMP_DIR}/text_image_chunk.png

    # put the layout qr code under
    touch ${TMP_DIR}/layout_metadata.txt
    echo "LEFT_MARGIN:${QRDUMP_A4_LEFT_MARGIN}" >> ${TMP_DIR}/layout_metadata.txt
    echo "RIGHT_MARGIN:${QRDUMP_A4_RIGHT_MARGIN}" >> ${TMP_DIR}/layout_metadata.txt
    echo "TOP_MARGIN:${QRDUMP_A4_TOP_MARGIN}" >> ${TMP_DIR}/layout_metadata.txt
    echo "BOTTOM_MARGIN:${QRDUMP_A4_BOTTOM_MARGIN}" >> ${TMP_DIR}/layout_metadata.txt

    perform_qr_encoding ${TMP_DIR}/layout_metadata.txt ${TMP_DIR}/layout_metadata
    
    local SIZE_Y_METADATA_LAYOUT=300

    pad_png_image ${TMP_DIR}/layout_metadata.png ${QRDUMP_A4_PIXELS_WIDTH} ${SIZE_Y_METADATA_LAYOUT} ${TMP_DIR}/metadata_layout_padded.png

    local SIZE_Y_METADATA_DATA=$(( ${QRDUMP_A4_PIXELS_HEIGHT} - ${QRDUMP_A4_TEXT_HEIGHT} - ${SIZE_Y_METADATA_LAYOUT} ))

    pad_png_image ${TMP_DIR}/metadata.png ${QRDUMP_A4_PIXELS_WIDTH} ${SIZE_Y_METADATA_DATA} ${TMP_DIR}/metadata_data_padded.png

    convert ${TMP_DIR}/text_1st_page.png ${TMP_DIR}/metadata_layout_padded.png ${TMP_DIR}/metadata_data_padded.png -append ${TMP_DIR}/first_page_full.png

    # all other pages: contain the data ----------------------
    # on all pages: use a fixed layout corresponding to the max number of bytes ie max size of the qr codes
    # TODO: make it adaptive; currently it is hard coded following the choice of bytes per qr-code

    # pad to a slightly larger size; this is hard coded, consider to fix?
    for CRRT_FILE in ${TMP_DIR}/data-*\.png; do
        local BASE_NAME=$(basename ${CRRT_FILE})
        pad_png_image ${CRRT_FILE} 269 269 ${TMP_DIR}/padded_${BASE_NAME}
    done

    # glue together 2 and 2 images to create a banner
    local LIST_PADDED_QR_DATA=$(ls ${TMP_DIR}/padded_data-*\.png | tr '\r\n' ' ')
    create_banner_of_qr_codes 1 ${TMP_DIR} ${LIST_PADDED_QR_DATA}

    # glue together banners to create pages
    local LIST_BANNER_QR_DATA=$(ls ${TMP_DIR}/banner_*\.png | tr '\r\n' ' ')
    create_page_of_qr_banners 1 ${TMP_DIR} ${LIST_BANNER_QR_DATA}

    # put all the pages together
    img2pdf --colorspace L --pagesize A4 -o ${TMP_DIR}/full_layout_QR_dump.pdf ${TMP_DIR}/first_page_full.png ${TMP_DIR}/data_page_*.png &> /dev/null
    sync

    cp ${TMP_DIR}/full_layout_QR_dump.pdf ${OUTPUT}
    sync
    rm -rf ${TMP_DIR}
}
