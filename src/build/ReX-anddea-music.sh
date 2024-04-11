#!/bin/bash
source src/build/utils.sh

initialize

#################################################

start "Patching YouTube Music APK with ReX forked by anddea..."

dl_gh "revanced-patches revanced-integrations" "anddea" "prerelease"
dl_gh "revanced-cli" "inotia00" "latest"
dl_apk "rex-music" "youtube-music" "google-inc/youtube-music/youtube-music" "arm64-v8a"

get_patches_key "com.google.android.apps.youtube.music"
[ -z $3 ] && get_ver "Enable color match player" "com.google.android.apps.youtube.music"

patch "rex-music" "anddea" "inotia"
purge "patches.json revanced-integrations-*.apk revanced-patches-*.jar revanced-cli-*.jar"

#################################################

start "Patching ReX Music APK with ReVanced..."

dl_gh "ReVanced-Patches ReVanced-Integrations" "ReVanced" "prerelease"
get_patches_key "com.google.android.apps.youtube.music" -
patch "rex-music" "anddea" - "./release/rex-music-anddea.apk"
purge "patches.json revanced-patches-*.jar revanced-integrations-*.apk"

#################################################

start "Injecting LSPatch..."

dl_gh "LSPatch" "LSPosed" "latest"
inject "rex-music" "anddea"
purge "jar-*.jar manager-*.apk"

#################################################

finalize
