#!/usr/bin/env bash
set -euf -o pipefail

# Run as user zimbra
if [[ $(id -nu) != "zimbra" ]]; then
  echo 'Run as zimbra!'
  exit 1
fi

usage() {
  cat <<-end
    Reset user account password and force user to change
    the default password after first successful login.

    Usage:
      $(basename ${0}) [-hef] <user-accounts>

    Option:
      -h          help
      -e          default password
      -f <file>   read list user from a file

      Example:
        $(basename ${0}) "user1@domain.com" "user2@domain.com"
        $(basename ${0}) -e "ChangeMe1!" -f list-accounts.txt

      Note: Using quote when passing user is recommended.
	end
}

__default='ChangeMe1!'
resetPass='/opt/zimbra/bin/zmprov setPassword'
modAcc='/opt/zimbra/bin/zmprov modifyAccount'
fileList=''

passOpts="\                                                                                                                                                               [6/681]
  zimbraPasswordMustChange TRUE \
  zimbraPasswordMinLength 8 \
  zimbraPasswordMinLowerCaseChars 1 \
  zimbraPasswordMinUpperCaseChars 1 \
  zimbraPasswordMinPunctuationChars 1 \
"
while getopts "he:f:" __option; do
  case ${__option} in
    h)
       usage
       exit 0
       ;;
    e)
       __default="${OPTARG}"
       ;;
    f)
       fileList="${OPTARG}"
       while IFS=$'\n' read -r user; do
         __err=$(${resetPass} ${user} ${__default} 2>&1 >/dev/null) && ${modAcc} ${user} ${passOpts}
         if [[ ${?} -eq 0 ]]; then
           echo -e "Password for ${user} has been set to \e[1m${__default}\e[0m"
         else
           echo -e "\e[91m${__err}\e[0m"
         fi
       done < ${fileList}
       ;;
    *)
       usage
       exit 1
       ;;
  esac
done

if [[ -z ${fileList} ]]; then
  shift $(expr ${OPTIND} - 1)
  while test ${#} -gt 0; do
    __err=$(${resetPass} ${1} ${__default} 2>&1 >/dev/null) && ${modAcc} ${1} ${passOpts}
    if [[ ${?} -eq 0 ]]; then
      echo -e "Password for ${1} has been set to \e[1m${__default}\e[0m"
    else
      echo -e "\e[91m${__err}\e[0m"
    fi
    shift
  done
fi
