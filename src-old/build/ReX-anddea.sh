#!/bin/bash
source src/build/utils.sh

init "google-inc" "youtube" "com.google.android.youtube"
using --inotia "anddea"

fetch --resolve-version
patch --dev "ReVanced-Patches ReVanced-Integrations"
inject

complete

#################################################

start "Patching YouTube APK with ReX forked by anddea..."

dl_gh "revanced-patches revanced-integrations" "anddea" "prerelease"
dl_gh "revanced-cli" "inotia00" "latest"

get_patches_key "com.google.android.youtube"
[ -z $3 ] && get_ver "Hide general ads" "com.google.android.youtube"

dl_apk "rex" "youtube" "google-inc/youtube/youtube"
patch "rex" "anddea" "inotia"
purge "patches.json revanced-integrations-*.apk revanced-patches-*.jar revanced-cli-*.jar"

#################################################

start "Injecting LSPatch..."

dl_gh "LSPatch" "LSPosed" "latest"
inject "rex" "anddea"
purge "jar-*.jar manager-*.apk"

#################################################

finalize
