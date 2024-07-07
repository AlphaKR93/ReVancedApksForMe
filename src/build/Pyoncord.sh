#!/bin/bash
# Twitter Piko
source src/build/utils.sh

initialize

#################################################

start "Downloading and Merging Discord APK..."

dl_gh "APKEditor" "REAndroid" "latest"
dl_apk "discord-bundled" "discord-chat-for-gamers" "discord-inc/discord-chat-for-gamers/discord-chat-for-gamers" "arm64-v8a"
merge "discord"
purge "APKEditor-*.jar"

#################################################

start "Injecting LSPatch..."

dl_gh "LSPatch" "LSPosed" "latest"
dl_gh "Pyoncord" "BunnyXposed" "latest"
inject "discord" "pyoncord" "app-release"

#################################################

finalize
