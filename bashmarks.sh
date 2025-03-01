# Copyright (c) 2010, Huy Nguyen, http://www.huyng.com
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided
# that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice, this list of conditions
#       and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#       following disclaimer in the documentation and/or other materials provided with the distribution.
#     * Neither the name of Huy Nguyen nor the names of contributors
#       may be used to endorse or promote products derived from this software without
#       specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


# USAGE:
# s bookmarkname - saves the curr dir as bookmarkname
# g bookmarkname - jumps to the that bookmark
# g b[TAB] - tab completion is available
# p bookmarkname - prints the bookmark
# p b[TAB] - tab completion is available
# d bookmarkname - deletes the bookmark
# d [TAB] - tab completion is available
# l - list all bookmarks

# setup file to store bookmarks
if [ ! -n "$SDIRS" ]; then
    export SDIRS=~/.sdirs
fi
touch "$SDIRS"

RED="0;31m"
GREEN="0;33m"

# save current directory to bookmarks
bashmarks_save_bookmark() {
    bashmarks_check_help $1
    _bookmark_name_valid "$@"
    if [ -z "$exit_message" ]; then
        _purge_line "$SDIRS" "export DIR_$1="
        CURDIR=$(echo $PWD| sed "s#^$HOME#\$HOME#g")
        echo "export DIR_$1=\"$CURDIR\"" >> $SDIRS
    fi
}

s() {
    bashmarks_save_bookmark "$@"
}

# jump to bookmark
bashmarks_goto_bookmark() {
    bashmarks_check_help $1
    source $SDIRS
    target="$(eval $(echo echo $(echo \$DIR_$1)))"
    if [ -d "$target" ]; then
        builtin cd "$target"
    elif [ ! -n "$target" ]; then
        echo -e "\033[${RED}WARNING: '${1}' bashmark does not exist\033[00m"
    else
        echo -e "\033[${RED}WARNING: '${target}' does not exist\033[00m"
    fi
}

g() {
    bashmarks_goto_bookmark "$@"
}

# jump to bookmark in windows explorer
bashmarks_open_in_explorer() {
    bashmarks_check_help $1
    source $SDIRS

	#If $1 is ".", set target to the current directory
	start_dir="$(pwd)"
	if [ "$1" == "." ]; then
		target="$(pwd)"
	else
		target="$(eval $(echo echo $(echo \$DIR_$1)))"
	fi

    if [ -d "$target" ]; then
        builtin cd "$target"
		explorer.exe .
		bultin cd "$start_dir"
    elif [ ! -n "$target" ]; then
        echo -e "\033[${RED}WARNING: '${1}' bashmark does not exist\033[00m"
    else
        echo -e "\033[${RED}WARNING: '${target}' does not exist\033[00m"
    fi
}

ep() {
    bashmarks_open_in_explorer "$@"
}

# print bookmark
bashmarks_print_bookmark() {
    bashmarks_check_help $1
    source $SDIRS
    echo "$(eval $(echo echo $(echo \$DIR_$1)))"
}

p() {
    bashmarks_print_bookmark "$@"
}

# delete bookmark
bashmarks_delete_bookmark() {
    bashmarks_check_help $1
    _bookmark_name_valid "$@"
    if [ -z "$exit_message" ]; then
        _purge_line "$SDIRS" "export DIR_$1="
        unset "DIR_$1"
    fi
}

d() {
    bashmarks_delete_bookmark "$@"
}

# print out help for the forgetful
bashmarks_check_help() {
    if [ "$1" = "-h" ] || [ "$1" = "-help" ] || [ "$1" = "--help" ] ; then
        echo ''
        echo 's <bookmark_name> - Saves the current directory as "bookmark_name"'
        echo 'g <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"'
        echo 'p <bookmark_name> - Prints the directory associated with "bookmark_name"'
        echo 'd <bookmark_name> - Deletes the bookmark'
        echo 'l                 - Lists all available bookmarks'
        kill -SIGINT $$
    fi
}

# list bookmarks with dirnam
bashmarks_list() {
    bashmarks_check_help $1
    source $SDIRS

    # if color output is not working for you, comment out the line below '\033[1;32m' == "red"
    env | sort | awk '/^DIR_.+/{split(substr($0,5),parts,"="); printf("\033[0;33m%-40s\033[0m %s\n", parts[1], parts[2]);}'

    # uncomment this line if color output is not working with the line above
    # env | grep "^DIR_" | cut -c5- | sort |grep "^.*="
}

l() {
    # TODO replace the short l at several places with this function
    # Using l, p, and so on in a large number of files makes later changes difficult.

    bashmarks_list "$@"

}

# list bookmarks without dirname
bashmarks_get_bookmark_names() {
    source $SDIRS
    env | grep "^DIR_" | cut -c5- | sort | grep "^.*=" | cut -f1 -d "="
}

_l() {
    bashmarks_get_bookmark_names
}

# validate bookmark name
_bookmark_name_valid() {
    exit_message=""
    if [ -z $1 ]; then
        exit_message="bookmark name required"
        echo $exit_message
    elif [ "$1" != "$(echo $1 | sed 's/[^A-Za-z0-9_]//g')" ]; then
        exit_message="bookmark name is not valid"
        echo $exit_message
    fi
}

# completion command
_comp() {
    local curw
    COMPREPLY=()
    curw=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W "$(eval bashmarks_get_bookmark_names)" -- $curw))
    return 0
}

# ZSH completion command
_compzsh() {
    reply=($(bashmarks_get_bookmark_names))
}

# safe delete line from sdirs
_purge_line() {
    if [ -s "$1" ]; then
        # safely create a temp file
        t=$(mktemp -t bashmarks.XXXXXX) || exit 1
        trap "/bin/rm -f -- '$t'" EXIT

        # purge line
        sed "/$2/d" "$1" > "$t"

        # this was probably causing symlinks to be replaced with files, so I removed it
        # /bin/mv "$t" "$1"

        cat "$t" > "$1"

        # cleanup temp file
        /bin/rm -f -- "$t"
        trap - EXIT
    fi
}

# bind completion command for g,p,d to _comp
if [ $ZSH_VERSION ]; then
    compctl -K _compzsh g
    compctl -K _compzsh p
    compctl -K _compzsh d
else
    shopt -s progcomp
    complete -F _comp g
    complete -F _comp p
    complete -F _comp d
	complete -F _comp ep
fi


bashmarks_clear_env_vars() {
    source $SDIRS
    for i in $(bashmarks_get_bookmark_names); do
        unset "DIR_$i"
    done
}


export bashmarks_bookmarks_folder="$HOME/.local/bashmarks-favorites"

bashmarks_set_SDIRS() {
    local filename="${1:-s}"  # default s for using normal .sdirs file

    local file_name="${bashmarks_bookmarks_folder}/${filename}"
    bashmarks_clear_env_vars
    if [ -f "$file_name" ]; then
        export SDIRS="$file_name"
    else
        echo "File $file_name does not exist"
    fi

    bashmarks_info
}


show_help() {
    cat <<HERE
    s  name            save the current directory as a bookmark
    g  name            go to the bookmark
    p  name            print the bookmark
    d  name            delete the bookmark
    l                  list  all bookmarks
    _l                 list all bookmarks without dirname

    bm  info           info - show the current bookmarks and the bookmarks folder
    bm  i              info - show the current bookmarks and the bookmarks folder

    bm  switch file    switch to another bookmark file (calls bms name)
    bm  s file         switch to another bookmark file (calls bms name)

    bm  h              help
    bm help            show the source code of the function bm

    bms file           switch (s = switch), use another bookmark file
    bms                show the source code of the function bm
HERE
}


list_bookmark_files() {
    # ls -1 $bashmarks_bookmarks_folder
    ls -l $bashmarks_bookmarks_folder
}


show_sdirs_and_bookmarks_folder() {
    echo-red $(basename $SDIRS)
    echo "SDIRS:                         $SDIRS"
    echo "bashmarks_bookmarks_folder:    $bashmarks_bookmarks_folder"
}

bashmarks_info() {
    show_sdirs_and_bookmarks_folder
    echo
    echo "bookmarks files"
    list_bookmark_files
}

bm() {
    local sub_command=$1
    shift

    [[ "$sub_command" == "" ]]        &&  show_help && return
    [[ "$sub_command" == "h" ]]       &&  show_help && return
    [[ "$sub_command" == "help" ]]    &&  declare -f bm && return                             # help
    [[ "$sub_command" == "-h" ]]      &&  declare -f bm && return
    [[ "$sub_command" == "info" ]]    &&  bashmarks_info && return
    [[ "$sub_command" == "i" ]]       &&  bashmarks_info && return
    [[ "$sub_command" == "l" ]]       &&  list_bookmark_files
    [[ "$sub_command" == "s" ]]       &&  bashmarks_set_SDIRS "$@"
    [[ "$sub_command" == "switch" ]]  &&  bashmarks_set_SDIRS "$@"
}


bm_define_aliases() {
    alias bmi="bm info"
    alias bmh="bm help"
    alias bms="bashmarks_set_SDIRS"
}

bm_define_aliases

# export some of the functions

export -f g
export -f bashmarks_save_bookmark

export -f l
export -f bashmarks_list

export -f p
export -f bashmarks_print_bookmark

export -f bashmarks_check_help

export -f bashmarks_clear_env_vars
