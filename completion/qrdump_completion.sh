# qrdump uses a very simple format:
# -O or --OOOO for name of the option
# in addition, some options expect following name / path /etc
# -O options are cryptic, only provide autocomplete for -- options?
# some options are mandatory at this point, automatically add?

#help,verbose,base64,debug,digest:,encode,decode,read-A4,output:,create-A4,safe-mode,input:,layout,extract

_qrdump(){
    COMPREPLY=()

    local LIST_OPTIONS_NOARG=" --help --verbose --base64 --debug --encode --decode --read-A4 --create-A4 --safe-mode --layout --extract "
    local LIST_OPTIONS_ARG=" --input --output --digest "

    local CRRT_ENTRY="${COMP_WORDS[COMP_CWORD]}"

    local PREVIOUS_ENTRY_TYPE="None"
    if [ "${COMP_CWORD}" -gt 1 ]; then
        local PREVIOUS_INDEX=$(( ${COMP_CWORD} - 1 ))
        local PREVIOUS_ENTRY="${COMP_WORDS[${PREVIOUS_INDEX}]}"

        if [[ "${LIST_OPTIONS_ARG}" = *" ${PREVIOUS_ENTRY} "* ]]; then
            PREVIOUS_ENTRY_TYPE="PATH_NEEDED"
        fi
    fi

    # TODO: case on this
    # if last word was an option that requires following path, provide paths
    # if last word was an option that does not require path, provide all options
    # if last word was path, provide all options
    case "$PREVIOUS_ENTRY_TYPE" in
        PATH_NEEDED)
            # TODO: make work on absolute paths
            COMPREPLY=($(compgen -f ${CRRT_ENTRY}))
            ;;
        *)
            COMPREPLY=($(compgen -W "$LIST_OPTIONS_ARG $LIST_OPTIONS_NOARG" -- "$CRRT_ENTRY"))
            ;;
    esac
}

complete -o filenames -F _qrdump qrdump
