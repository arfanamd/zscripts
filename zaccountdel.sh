#!/usr/bin/env bash
# zaccountdel.sh
# Usage:
# zaccountdel.sh <list-email-file>

set -uf -o pipefail

# check user
if [[ $(id -nu) != "zimbra" ]]; then
  printf "Error: run this script as user zimbra!\n"
  exit 1
fi

success=0
failed=0
file="${1}"
day="$(date +'%d%b%Y')"
log="/tmp/zaccountdel.log.${day}"

# check input file
if [[ ! -f ${file} ]]; then
  printf "Error: file ${file} doesn't exist.\n"
  exit 1
fi

test -f ${log} && truncate -s0 ${log}

# accounts creation process
while IFS=$'\n' read -r email; do
  zmprov da ${email} 2>> ${log}
  if [[ ${?} -eq 0 ]]; then
    ((success++)); printf "\e[92maccount\e[0m ${email} has been deleted.\n"
  else
    ((failed++)); printf "\e[91mfailed\e[0m to delete ${email}. Check out the log: ${log}\n"
  fi
done < "${file}"

printf "\nSummary: %d failed, %d deleted account(s).\n" ${failed} ${success}
