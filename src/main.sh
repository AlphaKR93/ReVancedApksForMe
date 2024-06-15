#!/bin/bash

source src/utils/logger.sh
source src/utils/annotations.sh

# Usage: init "(apkmirror publisher)" "(name)" "(package name)"
init() {
    _doing "Running initialize process..." "init $@"

    announce "Starting patch process for $2"

    clean all

    static publish "$1"
    static target  "$2"
    static package "$3"

    close
}

# Usage: using [--inotia] "(repo owner)"
using() {
    doing "Preparing environment..." "using $@"

    if [ $1 == "--inotia" ]; then
        info "Using inotia CLI"
        prepare "ReVanced-CLI" "inotia"
        static provider "inotia"; static source "$2"; return
    fi

    info "Using ReVanced CLI"
    prepare "ReVanced-CLI" "ReVanced"
    static provider "revanced"; static source "$1"; return

    close
}
