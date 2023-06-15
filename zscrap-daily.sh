#!/usr/bin/env bash
# usage: zscrap-daily.sh [date]
# date format is mm/dd/yy
set -euf -o pipefail

# check user
if [[ $(id -nu) != "zimbra" ]]; then
  printf -- "Run as zimbra!\n"
  exit 1
fi

# valid email admin account
_SCRAP_ACC='admin@'
_ZMSEARCH='/opt/zimbra/bin/zmmailbox'

# Zimbra by default generates the daily report on the midnight.
# using the date before today
_DATE="${1:-$(date --date='day ago' +'%x')}"
_KEYSEARCH="in:inbox date:${_DATE} Daily"

# get msg id
_ZMSGID=$(${_ZMSEARCH} -z -m ${_SCRAP_ACC} s -l 1 "${_KEYSEARCH}" | awk '/Daily/ {print $2}') && _ZMSGID=${_ZMSGID/-/}

# get delivered result
_ZMSG="$(${_ZMSEARCH} -z -m ${_SCRAP_ACC} gm ${_ZMSGID} | grep -E '[0-9]+...delivered')"
printf -- "%s: %s\n" "$(date --date=${_DATE} +'%a, %d %b %y')" "${_ZMSG:='NOTHING'}"
