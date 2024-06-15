#!/bin/bash
_APKM="https://www.apkmirror.com"
_QSRC="https://github.com/mgdm/htmlq/releases/latest/download/htmlq-x86_64-linux.tar.gz"
_QREF="htmlq.tar.gz"

_request() {
    local temp=$1
    [ $temp != "-" ] && temp="./download/$temp"

    wget -nv -O "$temp" --header="$_AGENT" "$__URI__" || rm -rf "$temp"
}
_AGENT="User-Agent: Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.231 Mobile Safari/537.36"

_deep_request() {
    cached __URI__ "$_APKM/apk/$2/"
    local output=$1 _RXP1="s/href=\"/@/g; s;.*${regexp}.*;\1;p"

    if [ -z $_HTMLQ ]; then
        info "Setting up HTMLQ..."
        pull $_QSRC $_QREF
        tar -xf "./$_QREF" -C "./"; purge "./$_QREF"
    fi

    __URI__="$_APKM$(_request - | tr '\n' ' ' | sed -n $_RXP1)"
    sleep 5

    __URI__="$_APKM$(_request - | grep "downloadButton" | sed -n $_RXP2)"
    sleep 5

    __URI__="$_APKM$(_request - | $_HTMLQ --base $_APKM --attribute href $_RXP3)"
    sleep 5

    _request "$output"
    unvar __URI__
}
_RXP2='s;.*href="\(.*key=[^"]*\)">.*;\1;p'
_RXP3='span > a[rel = nofollow]'

_merge() {
    doing "Merging $1..."
    exist "$basefile"
    
    if [ ! -f "APKEditor-*.jar" ]; then prepare "APKEditor" "REAndroid"; fi
	_eval "java -jar APKEditor-*.jar merge
		-i download/$1-bundled.apk
		-o download/$1.apk"
    close
}

# Usage: resolve [--bundled] "[arch]" "[api]" "[dpi]" "[publisher]" "[target]"
resolve() {
    local output="$target.apk" attempt=0 bundled="false" arch="" api="" dpi=""
    local versions=() _src="$publish/$target/$target" _cat=$target

	_doing "Attempting to download $_cat..." "resolve $@"

    if [ "$1" == "--bundled" ]; then
        bundled="true"; output="$target-bundled.apk"; arch=$2; api=$3; dpi=$4;
        [ "$arch" == "-" ] && arch=""; [ "$api" == "-" ] && api=""; [ "$dpi" == "-" ] && dpi=""
        if [ ! -z $5 ] && [ ! -z $6 ]; then _src="$5/$6/$6"; _cat=$6; fi
    else
        arch=$1; api=$2; dpi=$3;
        [ "$arch" == "-" ] && arch=""; [ "$api" == "-" ] && api=""; [ "$dpi" == "-" ] && dpi=""
        if [ ! -z $4 ] && [ ! -z $5 ]; then _src="$4/$5/$5"; _cat=$5; fi
    fi

	local rxp='APK</span>[^@]*@\([^#]*\)'
    [ ! -z $4 ] && rxp="$arch'\"[^@]*$api\"''\"[^@]*$dpi\"'</div>[^@]*@\\([^\"]*\\)"

	if [ -z $versions ]; then
		local response=$(_request - "$_APKM/uploads/?appcategory=$_cat"); debug "Response: $response"
		versions=$(sed -n $_RXP_VER <<< "$list_vers"); debug "Processed as: $versions"
  	fi

    verbose info "Found versions: ${versions[@]}"
	while [ $attempt -lt 10 ]; do
		local version=$(echo -e "$versions" | sed -n "$((attempt + 1))p")
		[ -z $version ] && fatal "No more versions to try"
    
		verbose info "Trying to download $_cat (version: $version, arch: $arch, api: $api, dpi: $dpi)"
		_deep_request "$output" "$_cat-${version//./-}-release" "$rxp"

		if [ -f "./download/$output" ]; then
            success "Successfully downloaded $_cat!"
            static basefile "$output"
            [ "$bundled" == "true" ] && _merge
            return
        fi

		warn "Failed to download $_cat, trying another version..."
		unvar version; ((attempt++))
	done

	if [ "$bundled" == "true" ]; then
        warn "attempting to download merged apk..."; resolve
    else
        fatal "No more versions to try"
    fi
	[ ! -f "./download/$output" ] && fatal "Failed to download $_cat"

	close
}
_RXP_VER='s;.*Version:</span><span class="infoSlide-value">\(.*\) </span>.*;\1;p'
