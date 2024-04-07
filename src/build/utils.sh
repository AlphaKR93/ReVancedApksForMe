#!/bin/bash

mkdir ./release ./download

#Setup HTMLQ
wget -q -O ./htmlq.tar.gz https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-linux.tar.gz
tar -xf "./htmlq.tar.gz" -C "./"
HTMLQ="./htmlq"

#################################################

# Colored output logs
green_log() {
    echo -e "\e[32m$1\e[0m"
}
red_log() {
    echo -e "\e[31m$1\e[0m"
}

#################################################

# Download Github assets requirement:
dl_gh() {
	if [ $3 == "latest" ] || [ $3 == "prerelease" ]; then
		local repo=$1
		for repo in $1 ; do
			local owner=$2 tag=$3 found=0 assets=0
			releases=$(wget -qO- "https://api.github.com/repos/$owner/$repo/releases")
			while read -r line; do
				if [[ $line == *"\"tag_name\":"* ]]; then
					tag_name=$(echo $line | cut -d '"' -f 4)
					if [ "$tag" == "$tag_name" ] || [ "$tag" == "latest" ] || [ "$tag" == "prerelease" ]; then
						found=1
					else
						found=0
					fi
				fi
				if [[ $line == *"\"prerelease\":"* ]]; then
					prerelease=$(echo $line | cut -d ' ' -f 2 | tr -d ',')
					if [ "$tag" == "prerelease" ] && [ "$prerelease" == "false" ]; then
						found=0
					elif [ "$tag" == "latest" ] && [ "$prerelease" == "true" ]; then
						found=0
					fi
				fi
				if [[ $line == *"\"assets\":"* ]]; then
					if [ $found -eq 1 ]; then
						assets=1
					fi
				fi
				if [[ $line == *"\"browser_download_url\":"* ]]; then
					if [ $assets -eq 1 ]; then
						url=$(echo $line | cut -d '"' -f 4)
							if [[ $url != *.asc ]]; then
							name=$(basename "$url")
							wget -q -O "$name" "$url"
							green_log "[+] Downloading $name from $owner"
						fi
					fi
				fi
				if [[ $line == *"],"* ]]; then
					if [ $assets -eq 1 ]; then
						assets=0
						break
					fi
				fi
			done <<< "$releases"
		done
	else
		for repo in $1 ; do
			wget -qO- "https://api.github.com/repos/$2/$repo/releases/tags/$3" \
			| jq -r '.assets[] | "\(.browser_download_url) \(.name)"' \
			| while read -r url names; do
				green_log "[+] Downloading $names from $2"
				wget -q -O "$names" $url
			done
		done
	fi
}

#################################################

# Get patches list:
get_patches_key() {
	excludePatches=""
	includePatches=""
	while IFS= read -r line1; do
 		red_log "[-] Excluded: $line1"
		excludePatches+=" -e \"$line1\""
	done < src/patches/$1/exclude-patches
	export excludePatches

	exclude=$(cat src/patches/$1/exclude-patches)
	patches=$(java -jar revanced-cli-*.jar list-patches revanced-patches-*.jar -f $1 | grep Name | cut -d " " -f 2-)
        for patch in ${patches// /_}; do
		rv=${patch//_/ }
		if ! grep -q "$rv" src/patches/$1/exclude-patches; then
			green_log "[+] Included: $rv"
			includePatches+=" -i \"${rv//"\""/"\\\""}\""
		fi
	done
	export includePatches
}

#################################################

# Find version supported:
get_ver() {
	version=$(jq -r --arg patch_name "$1" --arg pkg_name "$2" '
	.[]
	| select(.name == $patch_name)
	| .compatiblePackages[]
	| select(.name == $pkg_name)
	| .versions[-1]
	' patches.json)
 	[ "$version" == "null" ] && version=""
}

#################################################

# Download apks files from APKMirror:
_req() {
    if [ "$2" = "-" ]; then
        wget -nv -O "$2" --header="$3" "$1" || rm -f "$2"
    else
        wget -nv -O "./download/$2" --header="$3" "$1" || rm -f "./download/$2"
    fi
}
req() {
    _req "$1" "$2" "User-Agent: Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.231 Mobile Safari/537.36"
}

dl_apk() {
	local url=$1 regexp=$2 output=$3
	url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n "s/href=\"/@/g; s;.*${regexp}.*;\1;p")"
	sleep 5
	url="https://www.apkmirror.com$(req "$url" - | grep "downloadButton" | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
	sleep 5
   	url=$(req "$url" - | $HTMLQ --base https://www.apkmirror.com --attribute href "span > a[rel = nofollow]")
	sleep 5
	req "$url" "$output"
}
get_apk() {
	if [[ -z $4 ]]; then
		url_regexp='APK</span>[^@]*@\([^#]*\)'
	else
		case $4 in
			arm64-v8a) url_regexp='arm64-v8a'"[^@]*$6"''"[^@]*$5"'</div>[^@]*@\([^"]*\)' ;;
			armeabi-v7a) url_regexp='armeabi-v7a'"[^@]*$6"''"[^@]*$5"'</div>[^@]*@\([^"]*\)' ;;
			x86) url_regexp='x86'"[^@]*$6"''"[^@]*$5"'</div>[^@]*@\([^"]*\)' ;;
			x86_64) url_regexp='x86_64'"[^@]*$6"''"[^@]*$5"'</div>[^@]*@\([^"]*\)' ;;
			*) url_regexp='$4'"[^@]*$6"''"[^@]*$5"'</div>[^@]*@\([^"]*\)' ;;
		esac 
	fi
	export version="$version"
	local attempt=0
	while [ $attempt -lt 10 ]; do
		if [[ -z $version ]] || [ $attempt -ne 0 ]; then
			local list_vers v versions=()
			list_vers=$(req "https://www.apkmirror.com/uploads/?appcategory=$2" -)
			version=$(sed -n 's;.*Version:</span><span class="infoSlide-value">\(.*\) </span>.*;\1;p' <<<"$list_vers")
			version=$(grep -iv "\(beta\|alpha\)" <<<"$version")
			for v in $version; do
				grep -iq "${v} \(beta\|alpha\)" <<<"$list_vers" || versions+=("$v")
			done
			version=$(echo -e "$version" | sed -n "$((attempt + 1))p")
		fi
		green_log "[+] Downloading $2 version: $version $4 $5 $6"
		local base_apk="$1.apk"
		local dl_url=$(dl_apk "https://www.apkmirror.com/apk/$3-${version//./-}-release/" \
							  "$url_regexp" \
							  "$base_apk")
		if [[ -f "./download/$1.apk" ]]; then
			green_log "[+] Successfully downloaded $1"
			break
		else
			((attempt++))
			red_log "[-] Failed to download $1, trying another version"
			unset version list_vers v versions
		fi
	done
	if [ $attempt -eq 10 ]; then
		red_log "[-] No more versions to try. Failed download"
		return 1
	fi
}

#################################################

# Patching apps with Revanced CLI:
patch() {
	green_log "[+] Patching $1:"
	if [ -f "./download/$1.apk" ]; then
		local p b m ks a pu
		if [ "$3" = inotia ]; then
			p="patch " b="--patch-bundle" m="--merge" a="" ks="_ks"
			echo "Patching with Revanced-cli inotia"
		else
			if [[ $(ls revanced-cli-*.jar) =~ revanced-cli-([0-9]+) ]]; then
				num=${BASH_REMATCH[1]}
				if [ $num -ge 4 ]; then
					p="patch " b="--patch-bundle" m="--merge" a="" ks="ks" pu="--purge=true"
					echo "Patching with Revanced-cli version 4+"
				elif [ $num -eq 3 ]; then
					p="patch " b="--patch-bundle" m="--merge" a="" ks="_ks" pu="--purge=true"
					echo "Patching with Revanced-cli version 3"
				elif [ $num -eq 2 ]; then
					p="" b="-b" m="-m" a="-a " ks="_ks" pu="--clean"
					echo "Patching with Revanced-cli version 2"
				fi
			fi
		fi
        echo "The command line is: java -jar revanced-cli****.jar $p $b revanced-patches****.jar $m revanced-integrations****.apk $excludePatches $includePatches --options=./src/options/$2.json --out=./release/$1-$2.apk --keystore=./src/$ks.keystore $pu --force ./download/$a$1.apk"
		eval java -jar revanced-cli*.jar $p \
			$b revanced-patches*.jar \
			$m revanced-integrations*.apk \
			$excludePatches \
			$includePatches \
			--options=./src/options/$2.json \
			--out=./release/$1-$2.apk \
			--keystore=./src/$ks.keystore \
			$pu \
            --force \
			./download/$a$1.apk
    eval java -jar jar-*-release.jar ./release/*.apk -o ./release -f -r
  	unset version
		unset excludePatches
		unset includePatches
	else
		red_log "[-] Not found $1.apk"
		exit 1
	fi
}

#################################################

# Split architectures using Revanced CLI, created by j-hc or inotia00
archs=("arm64-v8a" "armeabi-v7a" "x86_64" "x86")
libs=("lib/armeabi-v7a lib/x86_64 lib/x86" "lib/arm64-v8a lib/x86_64 lib/x86" "lib/armeabi-v7a lib/arm64-v8a lib/x86" "lib/armeabi-v7a lib/arm64-v8a lib/x86_64")
gen_rip_libs() {
	for lib in $@; do
		echo -n "--rip-lib "$lib" "
	done
}
split_arch() {
	green_log "[+] Splitting $1 to ${archs[i]}:"
	if [ -f "./download/$1.apk" ]; then
		eval java -jar revanced-cli*.jar patch \
		--patch-bundle revanced-patches*.jar \
		--merge revanced-integrations*.apk\
		$excludePatches\
		$includePatches \
		--rip-lib res \
		--rip-lib classes \
		$3\
		--options=./src/options/$2.json \
		--keystore=./src/_ks.keystore \
		--out=./release/$2.apk\
		./download/$1.apk
	else
		red_log "[-] Not found $1.apk"
		exit 1
	fi
}
_libs=("armeabi-v7a x86_64 x86" "arm64-v8a x86_64 x86" "armeabi-v7a arm64-v8a x86" "armeabi-v7a arm64-v8a x86_64")
_gen_rip_libs() {
	for lib in $@; do
		echo -n "--rip-lib "$lib" "
	done
}
_split_arch() {
	green_log "[+] Splitting $1 to ${archs[i]}:"
	if [ -f "./release/$1.apk" ]; then
		eval java -jar revanced-cli*.jar patch \
		--patch-bundle revanced-patches*.jar \
		$3 \
		--keystore=./src/_ks.keystore \
		--out=./release/$2.apk\
		./release/$1.apk
	else
		red_log "[-] Not found $1.apk"
		exit 1
	fi
}
#################################################
