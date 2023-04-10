#!/usr/bin/env bash
# zaccountdel.sh
# Usage:
# zaccountdel.sh <csv-file>
#
# csv format is email

set -uf -o pipefail

# check user
if [[ $(id -nu) != "zimbra" ]]; then
  printf "Error: run this script as user zimbra!\n"
  exit 1
fi

success=0
failed=0
file="${1}"
day="$(date +'%d-%m-Y')"
log="/var/log/zaccountdel.${day}"

# check input file
if [[ ! -f ${file} ]]; then
  printf "Error: file ${file} doesn't exist.\n"
  exit 1
fi

# accounts creation process
while IFS=',' read -r email; do
  zmprov da ${email} 2>/dev/null
  if [[ ${?} -eq 0 ]]; then
    ((success++)); printf "account ${email} has been deleted.\n"
  else
    ((failed++)); printf "failed to delete ${email}. account not exist or data is invalid\n"
    printf "${email}\n" >> ${log}
  fi
done < "${file}"

printf "Summary: %d failed, %d deleted account(s).\n" ${failed} ${success}
