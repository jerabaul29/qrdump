# qrdump uses a very simple format:
# -O or --OOOO for name of the option
# in addition, some options expect following name / path /etc
# so workflow is:
# if last word was an option that requires following path, provide paths
# if last word was an option that does not require path, provide all options
# if last word was path, provide all options
# -O options are cryptic, only provide autocomplete for -- options?
# some options are mandatory at this point, automatically add?

#help,verbose,base64,debug,digest:,encode,decode,read-A4,output:,create-A4,safe-mode,input:,layout,extract

_qrdump(){
    COMPREPLY=()

    local LIST_OPTIONS_NOARG="--help --verbose --base64 --debug --encode --decode --read-A4 --create-A4 --safe-mode --layout --extract"
    local LIST_OPTIONS_ARG="--input --output --digest"

    local CRRT_ENTRY="${COMP_WORDS[COMP_CWORD]}"

    COMPREPLY=($(compgen -W "$LIST_OPTIONS_ARG $LIST_OPTIONS_NOARG" -- "$CRRT_ENTRY"))
}

complete -o filenames -F _qrdump qrdump
