# ZScripts

### Get mailbox quota (mailbox)
```
zmprov getQuotaUsage $(zmhostname) | awk '{ printf "user: %-25s, usage: %-5.2fKB, quota: %-5.2fKB\n", $1, ($3 / 1024), ($2 / 1024)}'
```

### Send email (mta)
```
cat <email-file> | /opt/zimbra/common/sbin/sendmail -t <recipient>
```

### List all active account
```
zmaccts | awk '$2 == "active" { print }' | sed -n '$!p'
```

### Get account index stat (mailbox)
```
zmprov getIndexStats <email-account>
```

### Modify mail quota
```
zmprov ma <email-account> zimbraMailQuota <size-in-byte>
```

### Get Zimbra account data in ldif format
```
ldapsearch -H ldapi:/// -x -LLL -b <ou=people,dc=your,dc=domain> -D <zimbra-ldap-user-dn> -w <zimbra-ldap-pass> '(&(objectClass=zimbraAccount)(uid=%s))' -f <list-account-without-domain>.txt
```

### Search message from user
```
zmmailbox -z -m <user-account> search -l 1000 "in:<path> [before|after|on|is]"
```

### Delete message from user
```
zmmailbox -z -m <user-account> deleteMessage <message-id>
```
