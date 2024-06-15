#!/bin/bash

# Usage: prepare "(repositories)" "(owner)" "[tag]"
prepare() {
    doing "Downloading assets from GitHub..." "prepare $@"

    local owner=$2 tag=$3
    [ -z $tag ] && tag="latest"

    # Process custom tags
    if [ $tag != "latest" ] && [ $tag != "prerelease" ]; then
        for repo in $1; do _tagged "$owner/$repo" "$tag"; done
        close; return
    fi

    # Process latest/prerelease
    for repo in $1; do _automate "$owner/$repo" "$tag"; done

    close; return
}

# _gh_dl "$source" "$name" "$uri"
_gh_dl() {
    verbose info "Downloading $2 from $1..."
    dl "$3" "$2"
    success "Successfully downloaded $2 from $1!"
}

# _tagged "$owner/$repo" "$tag"
_tagged() {
    verbose info "Attempting to download assets from $1..."
    local uri="https://api.github.com/repos/$1/releases/tags/$2"

    while read -r url names; do
        _gh_dl "$1" "$names" "$url"
    done <<< "$(get $uri | jq -r $_DL_TARGET)"
}
_DL_TARGET='.assets[] | "\(.browser_download_url) \(.name)"'

# _automate "$owner/$repo" "$tag"
_automate() {
    verbose info "Attempting to download assets from $1..."
    local found=0 assets=0 prerelease="false" url="" name=""

    while read -r line; do
        debug "Processing: $line"

        if [[ "$line" =~ "\"tag_name\":" ]]; then
            if [ "$2" == "$(echo $line | cut -d "\"" -f 4)" ]; then
                found=1
            elif [ "$2" == "latest" ] || [ "$2" == "prerelease" ]; then
                found=1
            fi
        fi

        # Process "prerelease"
        if [[ "$line" =~ "\"prerelease\":" ]]; then
            prerelease=$(echo $line | cut -d ' ' -f 2 | tr -d ',')
            if [ "$2" == "prerelease" ] && [ "$prerelease" == "false" ]; then
                found=0
            elif [ "$2" == "latest" ] && [ "$prerelease" == "true" ]; then
                found=0
            fi
        fi

        # Check response has assets
        [[ "$line" =~ *"\"assets\":"* ]] && [ $found -eq 1 ] && assets=1
        [ ! $assets -ne 1 ] && continue

        # Download assets
        if [[ "$line" =~ "\"browser_download_url\":" ]]; then
            uri=$(echo $line | cut -d '"' -f 4)
            if [[ ! "$uri" =~ ".asc" ]]; then
                _gh_dl "$1" "$(basename "$url")" "$uri"
            fi
        fi

        if [[ "$line" =~ "]," ]]; then assets=0 && break; fi

    done <<< "$(get "https://api.github.com/repos/$1/releases")"
}
