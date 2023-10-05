#!/usr/bin/env bash
#set -euf -o pipefail

if [[ $(id -nu) != 'zimbra' ]]; then
  echo '[error] Run as zimbra!'
  exit 1
fi

z_grant='/opt/zimbra/bin/zmprov grantRight'
z_revoke='/opt/zimbra/bin/zmprov revokeRight'
z_show='/opt/zimbra/bin/zmprov getGrants'
z_modify='/opt/zimbra/bin/zmprov modifyAccount'
z_check='/opt/zimbra/bin/zmprov getAccount'

MenuConsoleAccount='accountListView'
RightsOfAccount='domainAdminConsoleAccountRights adminConsoleAccountRights createAccount deleteAccount getAccount getAccountInfo countAccount changeAccountPassword listAccount modifyAccount moveAccountMailbox renameAccount setAccountPassword getAccountMembership'

MenuConsoleAlias='aliasListView'
RightsOfAlias='domainAdminConsoleAliasRights adminConsoleAliasRights addAccountAlias removeAccountAlias addGroupAlias removeGroupAlias countAlias createAlias deleteAlias listAlias listAccount'

MenuConsoleDL='DLListView'
RightsOfDL='domainAdminDistributionListRights adminConsoleDLRights domainAdminConsoleDLRights createDistributionList deleteDistributionList modifyDistributionList renameDistributionList getDistributionList listDistributionList countDistributionList addDistributionListMember getDistributionListMembership removeDistributionListMember removeDistributionListAlias addDistributionListAlias listAccount'

usage () {
  cat <<-eol
  Easy manage delegated admin.

  Synopsis:
  $(basename ${0}) [-s|-u] <arg> <user>

  Option:
  -s [account|alias|dl]     Specify rights that user will have.
  -u [account|alias|dl]     Revoke rights that user have.
  -h                        Print this help message.
	eol
}

checkUser() {
  echo "[*] checking user ${1}"
  ${z_check} ${1} &>/dev/null
  if [[ $? -ne 0 ]]; then
    echo "user ${1} doesn't exist!"
    exit 1
  fi
}

accountRight() {
  case ${1} in
    'grant')
      echo "[*] granting rights..."
      for right in ${RightsOfAccount}; do
        __dump=$(${z_grant} domain ${2} usr ${3} ${right} 2>&1)
      done
    ;;
    'revoke')
      echo "[*] revoking rights..."
      for right in ${RightsOfAccount}; do
        __dump=$(${z_revoke} domain ${2} usr ${3} ${right} 2>&1)
      done
    ;;
  esac
}

aliasRight() {
  case ${1} in
    'grant')
      echo "[*] granting rights..."
      for right in ${RightsOfAlias}; do
        __dump=$(${z_grant} domain ${2} usr ${3} ${right} 2>&1)
      done
    ;;
    'revoke')
      echo "[*] revoking rights..."
      for right in ${RightsOfAlias}; do
        __dump=$(${z_revoke} domain ${2} usr ${3} ${right} 2>&1)
      done
    ;;
  esac
}

distributionListRight() {
  case ${1} in
    'grant')
      echo "[*] granting rights..."
      for right in ${RightsOfDL}; do
        __dump=$(${z_grant} domain ${2} usr ${3} ${right} 2>&1)
      done
    ;;
    'revoke')
      echo "[*] revoking rights..."
      for right in ${RightsOfDL}; do
        __dump=$(${z_revoke} domain ${2} usr ${3} ${right} 2>&1)
      done
    ;;
  esac
}

checkRight() {
  ${z_show} -g usr ${1}
}

while getopts "hs:u:" __option; do
  case ${__option} in
    h)
      usage && exit 0
    ;;
    u)
      __action='revoke'
      __right="${OPTARG}"
			shift $(expr ${OPTIND} - 1)
      __user="${1}"
      __domain="${__user#*@}"
    ;;     
    s)
      __action='grant'
      __right="${OPTARG}"
			shift $(expr ${OPTIND} - 1)
      __user="${1}"
      __domain="${__user#*@}"
    ;;     
  esac
done

checkUser ${__user}
case ${__right} in
  'account')
    ${z_modify} ${__user} zimbraIsDelegatedAdminAccount TRUE zimbraAdminConsoleUIComponents ${MenuConsoleAccount}
    accountRight ${__action} ${__domain} ${__user}
  ;;
  'alias')
    ${z_modify} ${__user} zimbraIsDelegatedAdminAccount TRUE zimbraAdminConsoleUIComponents ${MenuConsoleAlias}
    aliasRight ${__action} ${__domain} ${__user}
  ;;
  'dl')
    ${z_modify} ${__user} zimbraIsDelegatedAdminAccount TRUE zimbraAdminConsoleUIComponents ${MenuConsoleDL}
    distributionListRight ${__action} ${__domain} ${__user}
  ;;
esac
checkRight ${__user} 
