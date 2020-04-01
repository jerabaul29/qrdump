# qrdump uses a very simple format:
# -O or --OOOO for name of the option
# in addition, some options expect following name / path /etc
# so workflow is:
# if last word was an option that requires following path, provide paths
# if last word was an option that does not require path, provide all options
# if last word was path, provide all options

_qrdump(){
    COMPREPLY=()

    LIST_OPTIONS=" "

    local CRRT_ENTRY="${COMP_WORDS[COMP_CWORD]}"

    COMPREPLY=($(compgen -W "$LIST_OPTIONS" -- "$CRRT_ENTRY"))
}

complete -o filenames -F _qrdump qrdump
