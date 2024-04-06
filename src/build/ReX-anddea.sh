#!/bin/bash

# ReX build
source src/build/utils.sh

#################################################

# Download requirements
dl_gh "revanced-patches revanced-integrations" "anddea" "latest"
dl_gh "revanced-cli" "inotia00" "latest"

#################################################

# Patch YouTube ReX:
get_patches_key "com.google.youtube"
if [[ -v 2 ]]; then version=$2; else get_ver "Hide general ads" "com.google.android.youtube"; fi
get_apk "youtube" "youtube" "google-inc/youtube/youtube"
patch "youtube" "ReX-anddea" "inotia"

#################################################

# Patch YouTube Music ReX:
get_patches_key "com.google.android.apps.youtube"
if [[ -v 3 ]]; then version=$3; else get_ver "Enable color match player" "com.google.android.apps.youtube.music"; fi
get_apk "youtube-music-arm64-v8a" "youtube-music" "google-inc/youtube-music/youtube-music" "arm64-v8a"
patch "youtube-music-arm64-v8a" "ReX-anddea" "inotia"

#################################################
