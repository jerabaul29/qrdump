# qrdump uses a very simple format:
# -O or --OOOO for name of the option
# in addition, some options expect following name / path /etc
# -O options are cryptic, only provide autocomplete for -- options?
# some options are mandatory at this point, automatically add?

#help,verbose,base64,debug,digest:,encode,decode,read-A4,output:,create-A4,safe-mode,input:,layout,extract

_qrdump(){
    COMPREPLY=()

    local LIST_OPTIONS_NOARG=" --help --verbose --base64 --debug --encode --decode --read-A4 --create-A4 --safe-mode --layout --extract --version "
    local LIST_OPTIONS_PATH=" --output "
    local LIST_OPTIONS_FILE=" --input "
    local LIST_OPTIONS_DIGEST=" --digest "

    local ALL_OPTIONS="$LIST_OPTIONS_PATH $LIST_OPTIONS_FILE $LIST_OPTIONS_NOARG $LIST_OPTIONS_DIGEST"

    local LIST_AVAIL_DIGEST=" sha1sum "

    local CRRT_ENTRY="${COMP_WORDS[COMP_CWORD]}"

    # are there previous entries?
    local PREVIOUS_ENTRY_TYPE="NONE"
    if [ "${COMP_CWORD}" -gt 1 ]; then
        local PREVIOUS_INDEX=$(( ${COMP_CWORD} - 1 ))
        local PREVIOUS_ENTRY="${COMP_WORDS[${PREVIOUS_INDEX}]}"

        # if the previous entry needs a path, must autocomplete path
        if [[ "${LIST_OPTIONS_PATH}" = *" ${PREVIOUS_ENTRY} "* ]]; then
            PREVIOUS_ENTRY_TYPE="PATH_NEEDED"
        fi

        # if the previous entry needs a file, must autocomplete file
        if [[ "${LIST_OPTIONS_FILE}" = *" ${PREVIOUS_ENTRY} "* ]]; then
            PREVIOUS_ENTRY_TYPE="FILE_NEEDED"
        fi

        # if the previous entry needs a digest, must autocomplete digest
        if [[ "${LIST_OPTIONS_DIGEST}" = *" ${PREVIOUS_ENTRY} "* ]]; then
            PREVIOUS_ENTRY_TYPE="DIGEST_NEEDED"
        fi
    fi

    # remove the options already used from the list
    for CRRT_PREVIOUS_ENTRY in ${COMP_WORDS[@]}; do
        CRRT_PREVIOUS_ENTRY="${CRRT_PREVIOUS_ENTRY} "
        ALL_OPTIONS=${ALL_OPTIONS/${CRRT_PREVIOUS_ENTRY}}
    done
    ALL_OPTIONS=${ALL_OPTIONS//  / }

    case "$PREVIOUS_ENTRY_TYPE" in
        PATH_NEEDED)
            COMPREPLY=($(compgen -d ${CRRT_ENTRY} -- "${CRRT_ENTRY}"))
            ;;
        FILE_NEEDED)
            COMPREPLY=($(compgen -f ${CRRT_ENTRY} -- "${CRRT_ENTRY}"))
            ;;
        DIGEST_NEEDED)
            COMPREPLY=($(compgen -W "${LIST_AVAIL_DIGEST}" -- "${CRRT_ENTRY}"))
            ;;
        *)
            # TODO: remove all options already used or incompatible (only 1 'command', 'input', 'output', same with all options)
            COMPREPLY=($(compgen -W "$ALL_OPTIONS" -- "$CRRT_ENTRY"))
            ;;
    esac
}

complete -o filenames -F _qrdump qrdump
