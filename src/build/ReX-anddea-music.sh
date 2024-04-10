#!/bin/bash

# ReX build
source src/build/utils.sh

#################################################

# Download requirements
dl_gh "revanced-patches revanced-integrations" "anddea" "prerelease"
dl_gh "revanced-cli" "inotia00" "latest"
dl_gh "lspatch" "lsposed" "latest"

#################################################

# Patch YouTube Music ReX:
get_patches_key "com.google.android.apps.youtube.music"
[ -z $3 ] && get_ver "Enable color match player" "com.google.android.apps.youtube.music"
get_apk "youtube-music-arm64-v8a" "youtube-music" "google-inc/youtube-music/youtube-music" "arm64-v8a"
patch "youtube-music-arm64-v8a" "ReX-anddea" "inotia"
inject_lspatch "youtube-music-arm64-v8a" "ReX-anddea"

#################################################
