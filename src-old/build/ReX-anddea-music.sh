#!/bin/bash
source src/build/utils.sh

init "google-inc" "youtube-music" "com.google.android.apps.youtube.music"
using --inotia "anddea"

fetch
patch --dev "ReVanced-Patches ReVanced-Integrations"
inject

complete
