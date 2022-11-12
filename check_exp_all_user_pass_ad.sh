#!/bin/bash

# check the expiration of all user passwords in AD

## Req: ldap-utils/openldap package
## If you have problems with TLS, add
## TLS_REQCERT never
## in to /etc/[open]ldap/ldap.conf

_AD_USER="username@domainname.com"
_AD_PASS="StrongPassword"
_AD_HOST="ldaps://server.domainname.com[:port]"
_AD_BASE="OU=Users,DC=domainname,DC=com"
_PW_POLICY=90
_WARN_DAYS=7
# ===========================================
# https://ldapwiki.com/wiki/Active%20Directory%20User%20Related%20Searches
# UserAccountControl:1.2.840.113556.1.4.803:=65536 = User Never Expire
# UserAccountControl:1.2.840.113556.1.4.803:=2 = User Locked
# ===========================================
_TODAY="$(date "+%s")"
_USERS="$(/usr/bin/ldapsearch \
    -H ${_AD_HOST} \
    -D "${_AD_USER}" \
    -w ${_AD_PASS} \
    -b "${_AD_BASE}" \
    -s sub "(&(objectClass=user)(objectClass=top)(objectClass=person)(!(UserAccountControl:1.2.840.113556.1.4.803:=65536))(!(UserAccountControl:1.2.840.113556.1.4.803:=2)))" \
    sAMAccountName mobile pwdLastSet 2>/dev/null \
    | tr -s "\n" " " | tr -s "#" "\n" | awk -F"pwdLastSet:" '{print $2}' | sed -e 's/[[:alpha:]]*:/:/g' -e 's/\+/00/g' -e 's/\s*//g' | awk NF)"

if [ -z "$_USERS" ]; then
    echo "USERS List is empty .. ldapsearch problem ?"
    exit 1
fi

for _U in $_USERS; do
    _NEVER_EXPIRE=""
    _DO_NOTIFY=""
    IFS=':' read -r -a array <<< "$_U"
    _LASTPW="$(expr ${array[0]} / 10000000 - 11644473600)"
    _DIFF_SECS="$(expr $_TODAY - $_LASTPW)"
    _DIFF_DAYS="$(expr $_DIFF_SECS / 86400)"
    _DAYS_REMAINING="$(expr $_PW_POLICY - $_DIFF_DAYS)"
    if [ "$_DAYS_REMAINING" -lt 0 ]; then
        _NEVER_EXPIRE=", Oops!"
    else
        if [ "$_DAYS_REMAINING" -le "$_WARN_DAYS" ]; then
            _DO_NOTIFY="WARN!"
            if [ ! -z "${array[3]}" ]; then
                # send SMS to lazy user
            fi
        fi
    fi
    echo "Days Remaining: $_DAYS_REMAINING, Login: ${array[1]}$_NEVER_EXPIRE $_TODO"
done
