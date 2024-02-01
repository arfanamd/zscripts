#!/usr/bin/env bash
set -uf -o pipefail

# only zimbra can run this script
if [[ $(command id -nu) != 'zimbra' ]]; then
	printf "[\e[31mERROR\e[0m] %s\n" "run as zimbra in mailbox node!"
	exit 1
fi

zmmbox='/opt/zimbra/bin/zmmailbox -z -m'
zmprov='/opt/zimbra/bin/zmprov -l'

search_pattern=""          # search pattern to use
list_user_file=""          # file contain list user
list_is_a_file=false       # state mode

usage() {
	local prog="$(command basename ${0})"
	cat <<- eom
Remove spam messages from users mailbox

Option:
  -h            print this help page
  -s <pattern>  search pattern to search spam message (mandatory)
  -f <file>     file contain list of users received spam messages (optional)

Usage:
  ${prog} -s "from:spam@dom.com subject:\"mail spam\" -f list-user.txt 
  ${prog} -s "from:spam@dom.com subject:\"mail spam\" user0@dom.com user1@dom.com
	eom
}
del_message_by_id() {
	declare -a msg_id
	local email="${1}"
	
	# check if account exist
	${zmprov} ga ${email} zimbraAccountStatus &>/dev/null
	if [[ ${?} -eq 0 ]]; then
		msg_id=$(${zmmbox} ${email} search -t message "${search_pattern}" 2>/dev/null | sed -e '1,4d' -e '/^$/d' | awk '{ print $2 }')
		
		if [[ -n ${msg_id} ]]; then
			for i in ${msg_id[@]}; do
				${zmmbox} ${email} deleteMessage ${i/-/}
				printf "[\e[32mDONE\e[0m] %s\n" "message ${i/-/} deleted for ${email}"
			done
		else
			printf "[\e[33mINFO\e[0m] %s\n" "message not found for ${email}"
		fi
	else
		printf "[\e[31mERROR\e[0m] %s\n" "user ${email} not found!"
	fi
}

while getopts "s:f:h" _option; do
	case "${_option}" in
		's')
			search_pattern="${OPTARG}"
			;;
		'f')
			list_user_file="${OPTARG}"
			list_is_a_file=true
			;;
		'h')
			usage
			exit 0
			;;
	esac
done

if [[ -z "${search_pattern}" ]]; then
	printf "[\e[31mERROR\e[0m] %s\n" "search pattern can't be empty!"
	exit 1
fi

if [[ ${list_is_a_file} == true ]]; then
	if [[ ! -f "${list_user_file}" ]]; then
		printf "[\e[31mERROR\e[0m] %s\n" "file ${list_user_file} not found!"
		exit 1
	fi

	while IFS=$'\n' read -rs email; do
		del_message_by_id "${email}"
	done < "${list_user_file}"
else
	shift $(expr ${OPTIND} - 1)
	while test ${#} -gt 0; do
		del_message_by_id "${1}"
		shift
	done
fi
# vim:ft=bash:ts=2:sw=2
