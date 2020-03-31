#!/bin/bash

##############################################
# verbose and debug functions                #
##############################################

GIVE_ACCESS=true

press_any(){
	if [ $GIVE_ACCESS = true ]
	then
	    echo "giving a chance to inspect the output"
	    read -n 1 -s -r -p "Press any key to continue"
	    echo " "
	fi
}

give_access(){
	if [ $GIVE_ACCESS = true ]
	then
    	nautilus . &
	fi
}

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

assert_file_or_folder_exists(){
    local VARNAME=$1
    local PATH=${!VARNAME}

    if [ -f "$PATH" ]; then
        :
    elif [ -d "$PATH" ]; then
        :
    else
        echo "$VARNAME is set to $PATH but no such file or folder"
        exit 1
    fi
}

assert_set(){
    local VARNAME=$1
    local VAR_CONTENT=${!VARNAME}

    if [ "${VAR_CONTENT:(-4)}" = "None" ]; then
        echo "variable $VARNAME is requested but not set"
        exit 1
    fi
}

assert_avail_folder(){
    local VARNAME=$1
    local DESTINATION=${!VARNAME}

    if [ ! -d "$DESTINATION" ]; then
        echo "variable $VARNAME is set to $DESTINATION but folder does not exist"
        exit 1
    fi
}

assert_avail_file_destination(){
    local VARNAME=$1
    local DESTINATION=${!VARNAME}

    if [ -f "$DESTINATION" ]; then
        echo "variable $VARNAME is set to $DESTINATION but file already exists"
        exit 1
    fi

    local HOSTING_FOLDER=$(dirname $DESTINATION)

    if [ ! -d ${HOSTING_FOLDER} ]; then
        echo "variable $VARNAME is set to $DESTINATION but hosting folder $HOSTING_FOLDER does not exist"
        exit 1
    fi
}

assert_avail_file(){
    local VARNAME=$1
    local DESTINATION=${!VARNAME}

    if [ ! -f $DESTINATION ]; then
        echo "variable $VARNAME is set to $DESTINATION but no such file"
        exit 1
    fi
}

assert_identical(){
    local FILE_1=$1
    local FILE_2=$2

    local DIGEST_1=$(sha512sum $1 | awk '{print $1;}')
    local DIGEST_2=$(sha512sum $2 | awk '{print $1;}')

    if [[ "${DIGEST_1}" = "${DIGEST_2}" ]]
    then
        echo "SAFE to use: success restoring check"
    else
        echo "UNSAFE to use: error restoring, non identical file!"
        exit 1
    fi
}

# digest_function(){
#     if [[ "$#" = "1" ]]
#     then
#         # this needs to be a file that exists
#         if [[ ! -f $1 ]]
#         then
#             echo "no file found attempting to digest"
#             exit 1
#         else
#             # success, file is here
#             local ARGTYPE="Filename"
#             local PARAM="$1"
#         fi
# 
#     # if giving data directly from std input
#     else
#         local ARGTYPE="StdInput"
#         local PARAM=$(cat)
#     fi
# 
#     # if using filepath
#     if [[ "${ARGTYPE}" = "Filename" ]]
#     then
#         if [[ "${DIGEST}" = "sha1sum" ]]
#         then
#             local DIGEST=$(sha1sum ${PARAM})
#         else
#             echo "unknown DIGEST ${DIGEST}"
#             exit 1
#         fi
# 
#     # if using std input
#     else
#         if [[ "${DIGEST}" = "sha1sum" ]]
#         then
#             local DIGEST=$(echo -n ${PARAM} | sha1sum)
#         else
#             echo "unknown DIGEST ${DIGEST}"
#             exit 1
#         fi
#     fi
# 
#     echo -n "${DIGEST}" | awk '{print $1;}' | xxd -r -ps
# }

perform_qr_encoding(){
    local FILE_TO_ENCODE=$1
    local DESTINATION=$2

    if [[ "${ENCODING}" = "base64"  ]]
    then
        base64 -w 0 < ${FILE_TO_ENCODE} | qrencode -l M -8 -o ${DESTINATION}.png
    fi
}

perform_qr_decoding(){
    local TO_DECODE=$1
    local DESTINATION=$2

    if [[ "${ENCODING}" = "base64"  ]]
    then
        zbarimg --raw --quiet "${TO_DECODE}" | base64 -di > "${DESTINATION}"
    fi
}

n_last_bytes(){
    # write the last $1 bytes of file $2 to $3
    local FILESIZE=$(stat -c%s "$2")
    show_debug_variable "FILESIZE"

    local NBYTES_TO_CUT=$((${FILESIZE}-$1))
    show_debug_variable "NBYTES_TO_CUT"

    dd if="$2" of="$3" ibs="${NBYTES_TO_CUT}" skip=1 status=none
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

