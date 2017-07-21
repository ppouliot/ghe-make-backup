## Function to send a notify a Dead Man's Snitch endpoint
function _notify_dms() {
    curl -s "${DMS_WEBHOOK}" &>/dev/null
}
