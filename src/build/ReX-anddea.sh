#!/bin/bash

# ReX build
source src/build/utils.sh

#################################################

# Download requirements
dl_gh "revanced-patches revanced-integrations" "anddea" "prerelease"
dl_gh "revanced-cli" "inotia00" "latest"

#################################################

# Patch YouTube ReX:
get_patches_key "com.google.android.youtube"
if [[ -v 2 ]]; then version=$2; else get_ver "Hide general ads" "com.google.android.youtube"; fi
get_apk "youtube" "youtube" "google-inc/youtube/youtube"
patch "youtube" "ReX-anddea" "inotia"

#################################################
