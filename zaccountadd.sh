#!/usr/bin/env bash
# zaccountadd.sh
# Usage:
# zaccountadd.sh <csv-file>
#
# csv format is email,password,name,description
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
log="/tmp/zaccountadd.${day}"

# check input file
if [[ ! -f ${file} ]]; then
  printf "Error: file ${file} doesn't exist.\n"
  exit 1
fi

test -f ${log} && truncate -s0 ${log}

# accounts creation process
while IFS=',' read -r email password name description; do
  id="$(zmprov ca ${email} ${password} displayName "${name}" description "${description}" 2>> ${log})"
  if [[ ${?} -eq 0 ]]; then
    ((success++)); printf "\e[92maccount\e[0m ${email} has been created.\n"
  else
    ((failed++)); printf "\e[91mfailed\e[0m to create ${email}. Check out the log: ${log}\n"
  fi
done < "${file}"

printf "\nSummary: %d failed, %d new account(s).\n" ${failed} ${success}
