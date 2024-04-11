#!/bin/bash
source src/build/utils.sh

initialize

#################################################

# Download requirements
dl_gh "revanced-patches revanced-integrations" "anddea" "prerelease"
dl_gh "revanced-cli" "inotia00" "latest"
dl_gh "lspatch" "lsposed" "latest"

#################################################

# Patch YouTube ReX:
get_patches_key "com.google.android.youtube"
[ -z $3 ] && get_ver "Hide general ads" "com.google.android.youtube"
dl_apk "youtube" "youtube" "google-inc/youtube/youtube"
patch "youtube" "ReX-anddea" "inotia"
inject "youtube" "ReX-anddea"

#################################################

finalize
