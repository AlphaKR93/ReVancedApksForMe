#!/bin/bash
# Twitter Piko
source src/build/utils.sh

#################################################

# Download requirements
dl_gh "piko revanced-integrations" "crimera" "prerelease"
dl_gh "revanced-cli" "revanced" "latest"
dl_gh "lspatch" "lsposed" "latest"
dl_gh "twifucker" "dr-tsng" "latest"

#################################################

# Patch Twitter Piko:

get_patches_key "com.twitter.android"
get_apk "twitter" "twitter" "x-corp/twitter/twitter"
patch "twitter" "piko"
java -jar jar-*-release.jar ./release/twitter-piko.apk -m TwiFucker-V*.apk -o ./release -f -r

#################################################

# Change Package Name:
get_patches_keys
dl_gh "revanced-patches revanced-integrations revanced-cli" "revanced" "prerelease"
patch "all" "piko"
