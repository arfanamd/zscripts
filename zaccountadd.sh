#!/usr/bin/env bash
# zaccountadd.sh
# Usage:
# zaccountadd.sh <csv-file>
#
# csv format is email,password,name,description
set -uf -o pipefail

if [[ $(id -nu) != "zimbra" ]]; then
  printf "Error: run this script as user zimbra!\n"
  exit 1
fi

success=0
failed=0
file="${1}"
day="$(date +'%d-%m-Y')"
log="/var/log/zaccountadd.${day}"

if [[ ! -f ${file} ]]; then
  printf "Error: file ${file} doesn't exist.\n"
  exit 1
fi

while IFS=',' read -r email password name description; do
  id="$(zmprov ca ${email} ${password} displayName "${name}" description "${description}" 2>/dev/null)"
  if [[ ${?} -eq 0 ]]; then
    ((success++)); printf "account ${email} has been created.\n"
  else
    ((failed++)); printf "failed to create ${email}. account exist or some data is invalid\n"
    printf "${email},${password},${name},${description}\n" >> ${log}
  fi
done < "${file}"

printf "Summary: %d failed, %d new account(s).\n" ${failed} ${success}
