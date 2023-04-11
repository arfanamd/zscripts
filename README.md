# ZScripts

### Get mailbox quota (mailbox)
`zmprov getQuotaUsage $(zmhostname) | awk '{ printf "user: %-25s, usage: %-5.2fKB, quota: %-5.2fKB\n", $1, ($3 / 1024), ($2 / 1024)}'`

### Send email (mta)
`cat <email-file> | /opt/zimbra/common/sbin/sendmail -t <recipient>`

### List all active account
`zmaccts | awk '$2 == "active" { print }' | sed -n '$!p'`

### Get account index stat (mailbox)
`zmprov getIndexStats <email-account>`

### Modify mail quota
`zmprov ma <email-account> zimbraMailQuota <size-in-byte>`

