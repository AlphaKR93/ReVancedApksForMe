#!/bin/bash
source src/build/utils.sh

initialize

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

start "Patching RVX Extended APK with ReVanced..."

dl_gh "ReVanced-Patches ReVanced-Integrations ReVanced-CLI" "ReVanced" "prerelease"
get_patches_key "com.google.android.youtube" -
patch "rex" "anddea" - "./release/rex-anddea.apk"
purge "patches.json revanced-patches-*.jar revanced-integrations-*.apk"

#################################################

start "Injecting LSPatch..."

dl_gh "LSPatch" "LSPosed" "latest"
inject "rex" "anddea"
purge "jar-*.jar manager-*.apk"

#################################################

finalize
