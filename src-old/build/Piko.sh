#!/bin/bash
source src/main.sh

init "x-corp" "twitter" "com.twitter.android"
using "crimera"

nofail || resolve --bundled "arm64-v8a"
missing --base && (nolog || resolve)

patch --dev "Piko ReVanced-Integrations"
patch --dev "ReVanced-Patches ReVanced-Integrations" "ReVanced" --reverse
inject

complete

################################################################################

task "Downloading and Merging Twitter APK..."

dl_gh "APKEditor" "REAndroid" "latest"
dl_apk "twitter-bundled" "twitter" "x-corp/twitter/twitter" "arm64-v8a"
merge "twitter"
purge "APKEditor-*.jar"

#################################################

task "Downloading Pre-requirements..."

dl_gh "ReVanced-CLI" "ReVanced" "latest"

#################################################

task "Patching Twitter APK with Piko..."

dl_gh "Piko ReVanced-Integrations" "Crimera" "prerelease"
get_patches_key "com.twitter.android"
patch "twitter" "piko"
purge "patches.json revanced-patches-*.jar revanced-integrations-*.apk"

#################################################

task "Patching Twitter-Piko APK with ReVanced..."

dl_gh "ReVanced-Patches ReVanced-Integrations" "ReVanced" "prerelease"
get_patches_key "com.twitter.android" -
patch "twitter" "piko" - "./release/twitter-piko.apk"
purge "patches.json revanced-patches-*.jar revanced-integrations-*.apk"

#################################################

task "Injecting LSPatch..."

dl_gh "LSPatch" "LSPosed" "latest"
inject "twitter" "piko" "TwiFucker"
purge "jar-*.jar TwiFucker-*.apk"

#################################################

finalize
