#!/bin/bash

export TZ=GMT
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

domain="mail.xxxx.com"
renew_date=`date +"%b %d %Y" -d "-10 days"`
renew_month=`echo ${renew_date} | awk -F' ' {' print $1 '}`
renew_day=`echo ${renew_date} | awk -F' ' {' print $2 '}`
exp_date=`echo | openssl s_client -servername ${domain} -connect ${domain}:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | awk -F'=' {'print $2'}`
exp_month=`echo ${exp_date} | awk -F' ' {' print $1 '}`
exp_day=`echo ${exp_date} | awk -F' ' {' print $2 '}`


get_X3_root() {
        wget https://letsencrypt.org/certs/trustid-x3-root.pem.txt -O /tmp/trustid-x3-root.pem.txt
}

action_renew() {
        sudo -u zimbra /opt/zimbra/bin/zmproxyctl stop
        sudo -u zimbra /opt/zimbra/bin/zmmailboxdctl stop
        /home/mihail/letsencrypt/certbot-auto  renew --force-renewal
        cd /opt/zimbra/ssl/letsencrypt/
        cp /etc/letsencrypt/live/${domain}/* .
        chown zimbra:zimbra /opt/zimbra/ssl/letsencrypt/*
        cat /tmp/trustid-x3-root.pem.txt >> /opt/zimbra/ssl/letsencrypt/chain.pem
        rm -f /tmp/trustid-x3-root.pem.txt
        sudo -u zimbra /opt/zimbra/bin/zmcertmgr verifycrt comm privkey.pem cert.pem chain.pem
        cp -a /opt/zimbra/ssl/zimbra /opt/zimbra/ssl/zimbra.$(date "+%Y%m%d")
        cp /opt/zimbra/ssl/letsencrypt/privkey.pem /opt/zimbra/ssl/zimbra/commercial/commercial.key
        sudo -u zimbra /opt/zimbra/bin/zmcertmgr deploycrt comm cert.pem chain.pem
        sudo -u zimbra /opt/zimbra/bin/zmcontrol restart
}

if [ ${exp_month} == ${renew_month} ]; then
        if [ ${exp_day} == ${renew_day} ]; then
                get_X3_root
                action_renew
        fi
fi
