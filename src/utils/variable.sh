#!/bin/bash

static() {
    [[ ${statics[@]} =~ $1 ]] && fatal "\"$1\" is already initialized"

    statics+=("$1")
    $1=$2
}

unvar() {
    [ $1 == "statics" ] && unvar "${statics[@]}" && return

    for var in $1; do
        verbose info "Removing variable: $var"
        unset $var
    done
}
