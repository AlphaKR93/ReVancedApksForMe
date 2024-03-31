#!/bin/bash
# ReX build
source src/build/utils.sh

#################################################

# Download requirements
dl_gh "revanced-patches revanced-integrations" "anddea" "latest"
dl_gh "revanced-cli" "inotia00" "latest"

#################################################

# Patch YouTube ReX:
get_patches_key "youtube-ReX-anddea"
get_ver "Hide general ads" "com.google.android.youtube"
get_apk "youtube" "youtube" "google-inc/youtube/youtube"
patch "youtube" "ReX-anddea" "inotia"

#################################################

# Patch YouTube Music ReX:
get_patches_key "youtube-music-ReX-anddea"
get_ver "Enable color match player" "com.google.android.apps.youtube.music"
get_apk "youtube-music-arm64-v8a" "youtube-music" "google-inc/youtube-music/youtube-music" "arm64-v8a"
patch "youtube-music-arm64-v8a" "ReX-anddea" "inotia"

#################################################

rm -f revanced-cli*
dl_gh "revanced-cli" "FiorenMas" "latest"
# Split architecture Youtube:
get_patches_key "youtube-ReX"
for i in {0..3}; do
    split_arch "youtube" "youtube-${archs[i]}-ReX" "$(gen_rip_libs ${libs[i]})"
done

#################################################
