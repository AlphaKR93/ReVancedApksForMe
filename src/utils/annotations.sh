nofail() {
    [ "$_nofail" == "true" ] && fatal "No fail already initialized!"
    _nofail=true
}

nolog() {
    [ "$_silent" == "true" ] && fatal "No log already initialized!"
    _silent=true
}
