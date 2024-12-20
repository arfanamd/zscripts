#!/usr/bin/env bash
set -uf -o pipefail

# Run as zimbra
if [[ $(id -nu) != "zimbra" ]]; then
  printf "Error: run as zimbra!\n"
  exit 1
fi

if [[ ${#} -lt 1 ]]; then
  cat <<-eol
  add accounts.

  Usage:
    $(basename ${0}) <csv-file>

  Note:
    csv format is email,password,name,description
	eol
	exit 0
fi

success=0
failed=0
file="${1}"

accAdd='/opt/zimbra/bin/zmprov createAccount'

# must to change password at first successful login
passOpts="\
  zimbraPasswordMustChange TRUE \
  zimbraPasswordMinLength 8 \
  zimbraPasswordMinLowerCaseChars 1 \
  zimbraPasswordMinUpperCaseChars 1 \
  zimbraPasswordMinPunctuationChars 1 \
"

# check input file
if [[ ! -f ${file} ]]; then
  printf "Error: file ${file} not exist.\n"
  exit 1
fi

# accounts creation process
while IFS='^' read -r email password name description; do
  id="$(${accAdd} ${email} ${password} displayName "${name}" description "${description}" ${passOpts} 2>&1)"
  if [[ ${?} -eq 0 ]]; then
    ((success++)); printf "\e[92maccount\e[0m ${email} has been created.\n"
  else
    ((failed++)); printf "\e[91mfailed\e[0m ${id}\n"
  fi
done < <(command gawk -v FPAT='([^,]+)|(\"[^\"]+\")' -v OFS='^' '{$1=$1; gsub(/"/,"",$0);} 1' ${file})

printf "\nSummary: %d failed, %d new account(s).\n" ${failed} ${success}
