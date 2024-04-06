#!/bin/bash
# Twitter Piko
source src/build/utils.sh

#################################################

# Download requirements
dl_gh "piko revanced-integrations" "crimera" "prerelease"
dl_gh "revanced-cli" "revanced" "latest"

#################################################

# Patch Twitter Piko:

get_patches_key "com.twitter.android"
get_apk "twitter" "twitter" "x-corp/twitter/twitter"
patch "twitter" "piko"

#################################################
