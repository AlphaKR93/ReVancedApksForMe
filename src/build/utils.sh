#!/bin/bash
VERBOSE=$1 DEBUG=$2 version=$3

# Colorful logs
log()      { echo -e      "\e[0m$1\e[0m"; }
error()    { echo -e "\e[31m[!] $1\e[0m"; }
success()  { echo -e "\e[32m[+] $1\e[0m"; }
warn()     { echo -e "\e[33m[-] $1\e[0m"; }
info()     { echo -e "\e[34m[*] $1\e[0m"; }
start()    { echo -e "\e[35m[&] $1\e[0m"; }
_log()     { echo -e "\e[96m[@] $1\e[0m"; }
debug()    { [ "$DEBUG" == "true" ] && echo -e "\e[90m[#] $1\e[0m"; }
verbose()  { [ "$VERBOSE" == "true" ] && $1 "$2"; }
_done()    { debug "Done."; }

verbose success "Verbose enabled"

# Purge
unvar() { for var in $1; do verbose info "Cleaning variables: $var"; unset $var; done }
purge() { for file in $1; do verbose info "Purging files: $file"; rm -rf $file; done }
_clear() {
	info "Purging files and variables..."
	purge "./download ./htmlq ./htmlq.tar.gz ./patches.json ./*.apk ./*.jar"
	unvar "includePatches excludePatches"
	_done
}

# Fatal Failure
fatal() { error "$1, aborting!"; _clear; exit 1; }
exist() {
	for file in $1; do
		[ ! -f "$(ls $file)" ] && fatal "Cannot find $file"
	done
}

# Evaluate
_eval() {
	local cmd="$(echo "$1" | sed 's/^[[:space:]]*/ /' | tr -d "\n")"
	log "Running command: $cmd"; eval $cmd;
}

# WGet
dl()  { wget -q -O $2 $1; }
get() { wget -qO- $1; }

#################################################

# Initializers
initialize() {
	_log "Starting patch process..."

	_clear; purge "./release"

	mkdir ./release ./download

	dl https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-linux.tar.gz htmlq.tar.gz
	tar -xf "./htmlq.tar.gz" -C "./"; purge "./htmlq.tar.gz"

	_done
}
finalize() { _clear; _log "Done!"; }

#################################################

# GitHub Releases assets downloader
dl_gh() {
	local owner=$2 tag=$3

	# Process custom tags
	if [ $tag != "latest" ] && [ $tag != "prerelease" ]; then
		for repo in $1; do
			verbose info "Attempting to download assets from $owner/$repo..."
			while read -r url names; do
				verbose info "Downloading $names from $owner..."
				dl "$url" "$names"
				success "Successfully downloaded $names from $owner!"
			done <<< "$(get "https://api.github.com/repos/$owner/$repo/releases/tags/$tag" \
				| jq -r '.assets[] | "\(.browser_download_url) \(.name)"')"
		done; _done; return
	fi

	# Process latest/prerelease
	for repo in $1; do
		verbose info "Attempting to download assets from $owner/$repo..."

		local found=0 assets=0 prerelease="false" url="" name="" releases=$(get "https://api.github.com/repos/$owner/$repo/releases")

		debug "Response is: $releases"

		while read -r line; do

			debug "Processing: $line"

			# Process "tag_name"
			if [[ "$line" =~ "\"tag_name\":" ]]; then
				if [ "$tag" == "$(echo $line | cut -d "\"" -f 4)" ]; then
					found=1
				elif [ "$tag" == "latest" ] || [ "$tag" == "prerelease" ]; then
					found=1
				fi
			fi

			# Process "prerelease"
			if [[ "$line" =~ "\"prerelease\":" ]]; then
				prerelease=$(echo $line | cut -d ' ' -f 2 | tr -d ',')
    				debug "Prerelease: $prerelease"
				if [ "$tag" == "prerelease" ] && [ "$prerelease" == "false" ]; then
					found=0
				elif [ "$tag" == "latest" ] && [ "$prerelease" == "true" ]; then
					found=0
				fi
			fi

			# Check response has assets
			[[ "$line" =~ *"\"assets\":"* ]] && [ $found -eq 1 ] && assets=1
   			debug "$found $assets"
			[ $assets -ne 1 ] && continue

			# Download assets
			if [[ "$line" =~ "\"browser_download_url\":" ]]; then
				url=$(echo $line | cut -d '"' -f 4)
				if [[ ! "$url" =~ ".asc" ]]; then
					name=$(basename "$url")
					verbose info "Downloading $name from $owner/$repo"
					dl "$url" "$name"
					success "Successfully downloaded $name from $owner/$repo!"
				fi
			fi

			if [[ "$line" =~ "]," ]]; then assets=0 && break; fi

		done <<< "$releases"
	done; _done
}

#################################################

# Get patches list:
get_patches_key() {
	info "Reading patches info..."
	patches=() excludePatches=() includePatches=(); local patch name
	exist "*-cli-*.jar *-patches-*.jar src/patches/$1/exclude-patches"

	info "Reading patches info..."
	patches=$(java -jar ./*-cli-*.jar list-patches ./*-patches-*.jar -f $1 | grep Name | cut -d " " -f 2-)
	debug "Response is: $patches"

	if [ "$2" == "-" ]; then
		verbose info "Reading included patches..."
		while IFS= read -r patch; do
			debug "Processing: $patch"
			if [[ $patches =~ $patch ]]; then
				success "Included: $patch"; includePatches+=" -i \"${patch//\"/\\\"}\""
			else
				error "Cannot find $patch in patches list!"
			fi
		done < src/patches/$1/include-patches

		verbose info "Processing excluded patches..."
		for patch in ${patches// /_}; do
			name=${patch//_/ }
			debug "Processing: $name"
			[[ $includePatches =~ $name ]] && continue

			warn "Excluded: $name"
			excludePatches+=" -e \"${name//\"/\\\"}\""
		done
		unvar "patches"; _done; return
	fi

	verbose info "Reading excluded patches..."
	while IFS= read -r patch; do
		debug "Processing: $patch"
		if [[ $patches =~ $patch ]]; then
			warn "Excluded: $patch"; excludePatches+=" -e \"${patch//\"/\\\"}\""
		else
			error "Cannot find $patch in patches list!"
		fi
	done < src/patches/$1/exclude-patches

	verbose info "Processing included patches..."
	for patch in ${patches// /_}; do
		name=${patch//_/ }
		debug "Processing: $name"
		[[ $excludePatches =~ $name ]] && continue

		success "Included: $name"
		includePatches+=" -i \"${name//\"/\\\"}\""
	done
	unvar "patches"; _done; return
}

#################################################

# Find version supported:
get_ver() {
	version=$(jq -r --arg patch_name "$1" --arg pkg_name "$2" '.[] | select(.name == $patch_name) | .compatiblePackages[] | select(.name == $pkg_name) | .versions[-1]' patches.json)
 	[ "$version" == "null" ] && version=""
}

#################################################

# Download apks files from APKMirror:
_req() {
	local header="User-Agent: Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.231 Mobile Safari/537.36"

    if [ "$2" == "-" ]; then
        wget -nv -O "$2" --header="$header" "$1" || rm -f "$2"
    else
        wget -nv -O "./download/$2" --header="$header" "$1" || rm -f "./download/$2"
    fi
}

_dl_apk() {
	local url=$1 regexp=$2 output=$3 htmlq="./htmlq"

	url="https://www.apkmirror.com$(_req "$url" - | tr '\n' ' ' | sed -n "s/href=\"/@/g; s;.*${regexp}.*;\1;p")"
	sleep 5

	url=$(_req "$url" - | $htmlq --base https://www.apkmirror.com --attribute href ".downloadButton")
	sleep 5

   	url=$(_req "$url" - | $htmlq --base https://www.apkmirror.com --attribute href "span > a[rel = nofollow]")
	sleep 5

	_req "$url" "$output"
}

dl_apk() {
	verbose info "Attempting to download $2..."
	local ver_fixed=$([ ! -z $version ] && echo true) base_apk="$1.apk" attempt=0 list_vers=() versions=() url_regexp='APK</span>[^@]*@\([^#]*\)'

	if [ ! -z $4 ]; then case $4 in
 		bundle) url_regexp='BUNDLE</span>[^@]*@\([^#]*\)' ;;
		arm64-v8a) url_regexp='arm64-v8a'"[^@]*$6"''"[^@]*$5"'</div>[^@]*@\([^"]*\)' ;;
		armeabi-v7a) url_regexp='armeabi-v7a'"[^@]*$6"''"[^@]*$5"'</div>[^@]*@\([^"]*\)' ;;
		x86) url_regexp='x86'"[^@]*$6"''"[^@]*$5"'</div>[^@]*@\([^"]*\)' ;;
		x86_64) url_regexp='x86_64'"[^@]*$6"''"[^@]*$5"'</div>[^@]*@\([^"]*\)' ;;
		*) url_regexp='$4'"[^@]*$6"''"[^@]*$5"'</div>[^@]*@\([^"]*\)' ;;
	esac; fi

	if [ -z $ver_fixed ]; then
		list_vers=$(_req "https://www.apkmirror.com/uploads/?appcategory=$2" -); debug "Response is: $list_vers"
		version=$(sed -n 's;.*Version:</span><span class="infoSlide-value">\(.*\) </span>.*;\1;p' <<< "$list_vers"); debug "Processed as: $version"
		for v in $version; do versions=(${versions[@]} $v); done
		verbose info "Found versions: ${versions[@]}"
  	fi

	while [ $attempt -lt 10 ]; do
		[ -z $ver_fixed ] && version=$(echo -e "$versions" | sed -n "$((attempt + 1))p")
		[ -z $version ] && fatal "No more versions to try"
    
		verbose info "Downloading $2 (version: $version, arch: $4, dpi: $5, android: $6)"
		local dl_url=$(_dl_apk "https://www.apkmirror.com/apk/$3-${version//./-}-release/" "$url_regexp" "$base_apk")

		[ -f "./download/$1.apk" ] && success "Successfully downloaded $2!" && break

		warn "Failed to download $1, trying another version..."
		[ -z $ver_fixed ] && unvar version
		((attempt++))
	done

	[ $attempt -eq 10 ] && if [ -z $4 ]; then
 		warn "attempting to download merged apk..."
   		dl_apk "$1" "$2" "$3"
     	else
 		fatal "No more versions to try"
	fi
	[ ! -f "./download/$1.apk" ] && fatal "Failed to download $1"

	_done
}

#################################################

# Merge APKs
merge() {
	info "Merging $1..."
	exist "./download/$1-bundled.apk APKEditor-*.jar"
	_eval "java -jar APKEditor-*.jar merge
		-i download/$1-bundled.apk
		-o download/$1.apk"
	_done
}

#################################################

# Patching apps with Revanced CLI:
patch() {
	info "Attempting to patch $1..."
	exist "revanced-cli-*.jar *-patches-*.jar ./download/$1.apk"

	local num=0 patch="patch " bundle="--patch-bundle" merge="--merge" ks="_ks" purge="--purge=true" dir="./download/$1.apk"

	if [ "$3" == "inotia" ]; then
		log "Patching with ReVanced-CLI by inotia"
	elif [[ $(ls revanced-cli-*.jar) =~ revanced-cli-([0-9]+) ]]; then
		num=${BASH_REMATCH[1]}

		if [ $num -eq 2 ]; then
			patch="" bundle="-b" merge="-m" ks="_ks" purge="--clean" dir="./download/ -a $1.apk"
		elif [ $num -ge 4 ]; then
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
		--out=./release/$1-$2.apk
		--keystore=./src/$ks.keystore
		$purge
		--force
		$dir"
	_done
}

#################################################

# Inject LSPatch:
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

#################################################
