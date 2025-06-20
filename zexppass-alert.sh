#!/usr/bin/env bash
# Author: arfanamd
# Note:   This script was tested using bash v5.1.8(1)-release.
# Usage:
#   - This script must be placed at the MTA node.
#   - This script must be runnig as zimbra.
#   - Run the script manually at first.
#     Optionally, you can activate debug mode for testing.
#   - Run daily at 3 A.M. as Zimbra cronjob:
#     0 3 * * * /path/to/the/script/zexppass-alert.sh

# Enable bash strict options.
set -euf -o pipefail

# Uncomment debug option below to enable debug mode.
#set -x

# Days to start the reminder.
declare -r START=7

# Account to use as the sender.
declare -r FROM='"Administrator" <admin@your.domain>'

# Program to send the remainder.
zsend="$(type -p sendmail)"

# XXX:
# My approach to retrieving data from Zimbra is to use `ldapsearch` because it is much faster
# compared to using `zmprov`. However, as a trade-off, we need to obtain some properties that
# are necessary to use `ldapsearch`. But trust me, it's worth it. Or you can even hardcoded
# the properties to make it run even faster. Just replace "LCONF" array with the hardcoded.
# one with this:
#
#LCONF[0]='<your-zimbra-ldap-url>' # I recomend you to use the LDAP Replica URL.
#LCONF[1]='<your-zimbra-ldap-userdn>'
#LCONF[2]='<your-zimbra-ldap-password>'
#
# And comment the "LCONF" array below.
#
LCONF=($(command ionice -c3 command zmlocalconfig -s -m nokey ldap_url zimbra_ldap_userdn zimbra_ldap_password))
ldap_search() {
    command ionice -c3 command ldapsearch -H "${LCONF[0]}" -x -LLL -D "${LCONF[1]}" -w "${LCONF[2]}" ${@}
}

# List of all accounts, excluding all the system accounts.
USERS=($(
    ldap_search '(&(objectClass=zimbraAccount)(!(zimbraIsSystemResource=TRUE))(zimbraAccountStatus=active))' 'zimbraMailDeliveryAddress' \
    | command awk -F ': ' '/^zimbra/ { print $2 }'
))

# Current date since epoch time.
declare -r DATE=$(command date +'%s')

for u in ${USERS[@]}; do
    # Get some account properties.
    p_last="$(ldap_search "(&(objectClass=zimbraAccount)(uid=${u%@*}))" 'zimbraPasswordModifiedTime' | command awk -F ': ' '/^zi/ { print $2 }')"
    p_last="${p_last:0:8}"
    p_mage="$(ldap_search "(&(objectClass=zimbraAccount)(uid=${u%@*}))" 'zimbraPasswordMaxAge' | command awk -F ': ' '/^zi/ { print $2 }')"
    p_mage="${p_mage:-0}"
    u_name="$(ldap_search "(&(objectClass=zimbraAccount)(uid=${u%@*}))" 'displayName' | command awk -F ': ' '/^di/ { print $2 }')"
    u_name="${u_name:-${u}}"
    
    # Skip if the account password age is not set.
    if [[ ${p_mage} -ne 0 ]]; then
        EXP=$(command date --date "${p_last} ${p_mage} days" +'%s')
        REM=$(( (${DATE} - ${EXP}) / -86400 ))

        # The account password expiry alert will be triggered when the expiry date is less than
        # ${START} days away. If ${REM} reached 0, send an email notice.
        if [[ ${REM} -le ${START} ]]; then
            if [[ ${REM} -ge 0 ]]; then
                # Send the alert.
                ${zsend} -f "${FROM}" "${u}" <<- ENDOFMESSAGE
Subject: Password Expiry Notice

Dear ${u_name},

Your account password will expire in ${REM} days.
Please update your password before the expiration date to avoid being locked out of your account.

Here is the step to change your password using Web Client:
  1. Login to your account using email web client.
  2. On the top right of your screen, click on your name to view drop-down menu.
  3. Click "Change Password"

Sincerely,
Administrator
ENDOFMESSAGE
            else
                # Send the alert.
                ${zsend} -f "${FROM}" "${u}" <<- ENDOFMESSAGE
Subject: Your Account Password Is Expired

Dear ${u_name},

Since you did not take action to update your account password in the last ${START} days, you are now
officially locked out of your account. Please contact the administrator team and request a password
reset if you would like to regain access to your email account.

Sincerely,
Administrator
ENDOFMESSAGE
            fi
        fi
    fi
done

# vim:ft=bash:ts=4:sw=4:nocin:noet:noai:si
