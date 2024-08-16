#!/bin/bash
# Twitter Piko
source src/build/utils.sh

initialize

#################################################

start "Downloading and Merging Twitter APK..."

dl_gh "APKEditor" "REAndroid" "latest"
dl_apk "twitter-bundled" "twitter" "x-corp/twitter/twitter" bundle
merge "twitter"
purge "APKEditor-*.jar"

#################################################

start "Downloading Pre-requirements..."

dl_gh "ReVanced-CLI" "ReVanced" "latest"

#################################################

start "Patching Twitter APK with Piko..."

dl_gh "Piko ReVanced-Integrations" "Crimera" "prerelease"
get_patches_key "com.twitter.android"
patch "twitter" "piko"
purge "patches.json *-patches-*.jar *-integrations-*.apk"

#################################################

start "Patching Twitter-Piko APK with ReVanced..."

dl_gh "ReVanced-Patches ReVanced-Integrations" "ReVanced" "prerelease"
get_patches_key "com.twitter.android" -
patch "twitter" "piko" - "./release/twitter-piko.apk"
purge "patches.json *-patches-*.jar *-integrations-*.apk"

#################################################

start "Injecting LSPatch..."

dl_gh "LSPatch" "LSPosed" "latest"
dl_gh "TwiFucker" "dr-tsng" "latest"
inject "twitter" "piko" "TwiFucker"
purge "jar-*.jar TwiFucker-*.apk"

#################################################

finalize
