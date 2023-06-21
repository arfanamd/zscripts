#!/usr/bin/env bash
set -uf -o pipefail

# check user
if [[ $(id -u) -ne 0 ]]; then
  echo 'Error: Run as root!'
  exit 1
fi

_logfile='/var/log/mail.log'
_logsumm='/opt/zimbra/common/bin/pflogsumm.pl'
_locconf='/opt/zimbra/bin/zmlocalconfig'

_maxhost=$(${_locconf} zimbra_mtareport_max_hosts | cut -d' ' -f3)
_maxuser=$(${_locconf} zimbra_mtareport_max_users | cut -d' ' -f3)

# generate log file specific for yesterday's date.
# reason? accuracy.
_timestmp="$(date -d yesterday +'%b %_d')"
_logugen="$(sed 's/ //g' <<< ${_timestmp})" && _logugen="/tmp/${_logugen}.log"

grep "^${_timestmp}" ${_logfile}.1 > ${_logugen}
grep "^${_timestmp}" ${_logfile} > ${_logugen}

# delivered line
_delivered="$(${_logsumm} --detail 0 -u ${_maxuser} -h ${_maxhost} -d yesterday ${_logugen} | awk 'NR == 8 { print $1 }')"
if [[ ${_delivered} =~ 'k' ]]; then
  _realdeliv=$((${_delivered/k/} * 1024))
elif [[ ${_delivered} =~ 'm' ]]; then
  _realdeliv=$((${_delivered/m/} * 1048576))
else
  _realdeliv=${_delivered}
fi

rm ${_logugen}
echo "${_timestmp}: ${_delivered} -> ${_realdeliv}"

# vim:bg=dark:ft=bash:sw=2:ts=4:expandtab
