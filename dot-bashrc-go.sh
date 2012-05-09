# bash rc file

# Copyright (c) 2005, "Brandon L. Golm" <br@ndon.com>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# Neither the name of the creator nor the names of its contributors may
# be used to endorse or promote products derived from this software
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES OF ANY KIND.


### README ###
#
##  Provides a "cd to favorite directory" shortcut, with tab completion
#
# Source this file in your .bashrc, .profile, or other startup file.
# . dot-bashrc-go.sh [path-to-config-file]  # default file is ~/.gorc
#
# Config files use the following syntax:
#    /home/username/full/path/to/some_dir
#    laser=/var/db/superawesomemetaschamafile
#
# Usage:
#   go some_dir    # cd to first path above
#   go laser       # cd to second path above
#   go laser/cats  # "cd /var/db/superawesomemetaschamafile/cats" per above
#   go foo         # "cd ~/foo/", if that fails "cd foo/"
#   go <TAB>       # show completions for config file
#   go l<TAB>      # will complete "laser"
#   go laser/c<TAB> # not implemented yet


if [[ -n "$1" ]]; then
    GORC="$1"
    shift
else
    GORC=~/.gorc
fi


go () {
    local i=0
    local key=$1
    local dir=''
    if [[ $key == */* ]]; then
        dir=/${key#*/}
        key=${key%%/*}
    fi
    while [[ $i -lt ${#FAVORITE_DIRECTORIES_KEYS[*]} ]]; do
        if [[ $key == ${FAVORITE_DIRECTORIES_KEYS[$i]} ]]; then
            if [[ ${FAVORITE_DIRECTORIES[$i]} == /* ]]; then
                cd "${FAVORITE_DIRECTORIES[$i]}${dir}"
            else
                cd ~/"${FAVORITE_DIRECTORIES[$i]}${dir}"
            fi
            return
        fi
        let "i++"
    done
    cd $1
}

go_read_favorite_directories () {
    # this function imports the config into some globals.
    local IFS='
'
    local key
    local val
    local n
    local i=0
    FAVORITE_DIRECTORIES_KEYS=()
    FAVORITE_DIRECTORIES=()
    if [[ ! -e "$GORC" ]]; then
        return
    fi
    while read n  # <$GORC
    do
        if [[ $n == \#* || -z $n ]]; then continue; fi
        if [[ $n == *=* ]]; then
            key=${n%%=*}
            val=${n#*=}
        else
            key=`basename $n`
            val=$n
        fi
        FAVORITE_DIRECTORIES_KEYS[$i]=$key
        FAVORITE_DIRECTORIES[$i]=$val
        shift
        let "i++"
    done <"$GORC"
    export FAVORITE_DIRECTORIES_KEYS
    export FAVORITE_DIRECTORIES
}

go_complete_favorite_directories () {
    local i=0
    COMPREPLY=()
    if [[ -z $2 ]]; then
        COMPREPLY=(${FAVORITE_DIRECTORIES_KEYS[@]})
    elif [[ $2 == */* ]]; then
        local key=$2
        local dir=/${key#*/}
        key=${key%%/*}
        local subdir
        while [[ $i -lt ${#FAVORITE_DIRECTORIES_KEYS[*]} ]]; do
            if [[ ${FAVORITE_DIRECTORIES_KEYS[$i]} = ${key}* ]]; then
                local base=`go ${key}; pwd`
                for subdir in ~/${FAVORITE_DIRECTORIES[$i]}${dir}*
                do
                    subdir=${subdir/#${base}}
                    if [[ -d ~/${FAVORITE_DIRECTORIES[$i]}$subdir ]]; then
                        COMPREPLY=(${COMPREPLY[@]} ${key}${subdir#${FAVORITE_DIRECTORIES[$i]}})
                    fi
                done
            fi
            let "i++"
        done
    else
        while [[ $i -lt ${#FAVORITE_DIRECTORIES_KEYS[*]} ]]; do
            if [[ ${FAVORITE_DIRECTORIES_KEYS[$i]} = ${2}* ]]; then
                COMPREPLY=(${COMPREPLY[@]} ${FAVORITE_DIRECTORIES_KEYS[$i]})
            fi
            let "i++"
        done
    fi
}
complete -F go_complete_favorite_directories go

go_write_favorite_directories () {
    return
}

alias set_fav=go_read_favorite_directories
go_read_favorite_directories

