QRDUMP_PARAMS_NO_PRINT="False"
SAVED_VERBOSE="$VERBOSE"
SAVED_DEBUG="$DEBUG"

while test $# -gt 0
do
    case "$1" in
        --no-print)
            QRDUMP_PARAMS_NO_PRINT="True"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ $QRDUMP_PARAMS_NO_PRINT = "True" ]; then
    VERBOSE="False"
    DEBUG="False"
fi

echo_verbose "----------------------------------------"
echo_verbose "show qrdump params"

# using no digest for now; todo: check
# SIZE_DIGEST="$(echo -n "anything" | digest_function | wc -c)"
SIZE_DIGEST=0
show_debug_variable SIZE_DIGEST

QRDUMP_SIZE_ID=8
show_debug_variable QRDUMP_SIZE_ID

# the max information content of a qr-code depending
# of its size is given by the 'version table'.
# see for example: https://web.archive.org/web/20160326120122/http://blog.qr4.nl/page/QR-Code-Data-Capacity.aspx
# be a bit conservative about qr code size
# to be nice to possible bad printers
QRDUMP_MAX_QR_SIZE=331
show_debug_variable QRDUMP_MAX_QR_SIZE

# the rank size in the data QR metadata
QRDUMP_SIZE_RANK=2
show_debug_variable QRDUMP_SIZE_RANK

QRDUMP_SIZE_DATAQR_METADATA="$((${QRDUMP_SIZE_RANK}+${QRDUMP_SIZE_ID}))"
QRDUMP_CONTENT_QR_CODE_BYTES="$((${QRDUMP_MAX_QR_SIZE}-${QRDUMP_SIZE_DATAQR_METADATA}))"
show_debug_variable QRDUMP_SIZE_DATAQR_METADATA
show_debug_variable QRDUMP_CONTENT_QR_CODE_BYTES

# Equivalent A4 paper dimensions in pixels at 300 DPI and 72 DPI respectively are: 2480 pixels x 3508 pixels (print resolution) 595 pixels x 842 pixels (screen resolution)
# TODO: compute with logics, allow to adapt to dpi
# layout information: left margin, inter-margin right-left, right margin,
# line jump margin, top margin, bottom margin
QRDUMP_A4_PIXELS_WIDTH=595
QRDUMP_A4_PIXELS_HEIGHT=842
QRDUMP_A4_LEFT_MARGIN=60
QRDUMP_A4_RIGHT_MARGIN="${QRDUMP_A4_LEFT_MARGIN}"
QRDUMP_A4_TOP_MARGIN=100
QRDUMP_A4_BOTTOM_MARGIN="${QRDUMP_A4_TOP_MARGIN}"
QRDUMP_A4_LINE_JUMP=100
# text
# 595 - 60 - 60
QRDUMP_A4_TEXT_WIDTH=475
QRDUMP_A4_TEXT_HEIGHT=250

show_debug_variable QRDUMP_A4_PIXELS_WIDTH
show_debug_variable QRDUMP_A4_PIXELS_HEIGHT
show_debug_variable QRDUMP_A4_LEFT_MARGIN
show_debug_variable QRDUMP_A4_RIGHT_MARGIN
show_debug_variable QRDUMP_A4_TOP_MARGIN
show_debug_variable QRDUMP_A4_BOTTOM_MARGIN
show_debug_variable QRDUMP_A4_LINE_JUMP
show_debug_variable QRDUMP_A4_TEXT_WIDTH
show_debug_variable QRDUMP_A4_TEXT_HEIGHT

QRDUMP_PARCHIVE_SIZE=512
QRDUMP_PARCHIVE_REDUNDANCY=15

show_debug_variable QRDUMP_PARCHIVE_SIZE
show_debug_variable QRDUMP_PARCHIVE_REDUNDANCY

echo_verbose "----------------------------------------"
echo_verbose " "

QRDUMP_PARAMS_NO_PRINT="False"
VERBOSE="$SAVED_VERBOSE"
DEBUG="$SAVED_DEBUG"
