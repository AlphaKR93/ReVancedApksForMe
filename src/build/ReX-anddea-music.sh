#!/bin/bash
source src/build/utils.sh

initialize

#################################################

# Download requirements
dl_gh "revanced-patches revanced-integrations" "anddea" "prerelease"
dl_gh "revanced-cli" "inotia00" "latest"
dl_gh "lspatch" "lsposed" "latest"

#################################################

# Patch YouTube Music ReX:
get_patches_key "com.google.android.apps.youtube.music"
[ -z $3 ] && get_ver "Enable color match player" "com.google.android.apps.youtube.music"
dl_apk "youtube-music-arm64-v8a" "youtube-music" "google-inc/youtube-music/youtube-music" "arm64-v8a"
patch "youtube-music-arm64-v8a" "ReX-anddea" "inotia"
inject "youtube-music-arm64-v8a" "ReX-anddea"

#################################################

finalize
