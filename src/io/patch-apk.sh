#!/bin/bash

patch() {
	doing "Attempting to patch $1..." "patch $@"
	local num=0 patch="patch " bundle="--patch-bundle" merge="--merge" ks="_ks"
    local purge="--purge=true" reverse="" repo=$source
    local output="./release/$target-$source.apk"

	exist "revanced-cli-*.jar $basefile"

    if [ "$1" == "--dev" ]; then
        [ ! -z $3 ] && repo=$3
        prepare $2 $repo prerelease
        reverse=$4
    else
        [ ! -z $2 ] && repo=$2
        prepare $1 $repo prerelease
        reverse=$3
    fi

    exist "*-patches-*.jar"

	if [ "$provider" == "inotia" ]; then
		log "Patching with ReVanced-CLI by inotia"
	elif [[ $(ls revanced-cli-*.jar) =~ revanced-cli-([0-9]+) ]]; then
		num=${BASH_REMATCH[1]}

		if [ $num -ge 4 ]; then
			ks="ks"
		else
			fatal "Unsupported ReVanced-CLI version: $num"
		fi

		log "Patching with ReVanced-CLI version $num"
	fi

	[ "$3" == "-" ] && dir=$4
	[ "$4" == "-" ] && dir=$5

	_eval "java -jar revanced-cli-*.jar $patch
		$bundle *-patches-*.jar
		$merge *-integrations-*.apk
		$excludePatches
		$includePatches
		--options=./src/options/$2.json
		--out=$output
		--keystore=./src/$ks.keystore
		$purge
		--force
		$dir"
    basefile=$output
	close
}

inject() {
	info "Injecting LSPatch to $1..."
	exist "jar-*.jar ./release/$1-$2.apk"

	local m=""
	[ ! -z $3 ] && m="--embed $3"

	_eval "java -jar jar-*-release.jar
		./release/$1-$2.apk
		--output ./release
		--allowdown
		--force
		--verbose
		$m"
	mv ./release/$1-$2-*-lspatched.apk ./release/$1-$2.apk -f
	_done
}
