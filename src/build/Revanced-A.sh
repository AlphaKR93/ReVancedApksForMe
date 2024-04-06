#!/bin/bash
exit
# Revanced build
source ./src/build/utils.sh

#################################################

# Download requirements
dl_gh "revanced-patches revanced-integrations" "revanced" "prerelease"
dl_gh "revanced-cli" "revanced" "latest"

#################################################

# Patch Instagram:
# Arm64-v8a
# get_patches_key "instagram"
# #get_ver "Hide timeline ads" "com.instagram.android"
# get_apk "instagram-arm64-v8a-beta" "instagram-instagram" "instagram/instagram-instagram/instagram-instagram" "arm64-v8a" "nodpi"
# patch "instagram-arm64-v8a-beta" "revanced"

#################################################

# Patch Messenger:
# Arm64-v8a
# get_patches_key "messenger"
# get_apk "messenger-arm64-v8a-beta" "messenger" "facebook-2/messenger/messenger" "arm64-v8a" "nodpi"
# patch "messenger-arm64-v8a-beta" "revanced"

#################################################

# Patch Twitter:
# get_patches_key "twitter"
# get_apk "twitter-beta" "twitter" "x-corp/twitter/twitter"
# patch "twitter-beta" "revanced"

#################################################

# Patch Twitch:
# get_patches_key "twitch"
# get_ver "Block audio ads" "tv.twitch.android.app"
# get_apk "twitch-beta" "twitch" "twitch-interactive-inc/twitch/twitch"
# patch "twitch-beta" "revanced"

#################################################

# Patch Reddit:
# get_patches_key "reddit"
# get_apk "reddit-beta" "reddit" "redditinc/reddit/reddit"
# patch "reddit-beta" "revanced"

#################################################

# Patch Tiktok:
# get_patches_key "tiktok"
# get_ver "Feed filter" "com.ss.android.ugc.trill"
# get_apk "tiktok-beta" "tik-tok" "tiktok-pte-ltd/tik-tok/tik-tok"
# patch "tiktok-beta" "revanced"

#################################################

# Patch Facebook:
# Arm64-v8a
# get_patches_key "facebook"
# get_apk "facebook-arm64-v8a-beta" "facebook" "facebook-2/facebook/facebook" "arm64-v8a" "nodpi" "Android 11+"
# patch "facebook-arm64-v8a-beta" "revanced"

#################################################

# Patch Pixiv:
# get_patches_key "pixiv"
# get_apk "pixiv-beta" "pixiv" "pixiv-inc/pixiv/pixiv"
# patch "pixiv-beta" "revanced"

#################################################

# Patch Lightroom:
# get_patches_key "lightroom"
# get_apk "lightroom-beta" "lightroom" "adobe/lightroom/lightroom" "arm64-v8a"
# patch "lightroom-beta" "revanced"

#################################################

# Patch Windy:
# get_patches_key "windy"
# version="34.0.2"
# get_apk "windy" "windy-wind-weather-forecast" "windy-weather-world-inc/windy-wind-weather-forecast/windy-wind-weather-forecast"
# patch "windy" "revanced"

#################################################

# Patch Tumblr:
# get_patches_key "tumblr"
# version="33.2.0.110"
# get_apk "tumblr-beta" "tumblr" "tumblr-inc/tumblr/tumblr"
# patch "tumblr-beta" "revanced"

#################################################
