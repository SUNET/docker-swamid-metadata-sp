#!/bin/sh -x

printenv

export KEYDIR=/etc/shibboleth/certs
if [ ! -f "$KEYDIR/sp-signing-key.pem" -o ! -f "$KEYDIR/sp-encrypt-key.pem" ]; then
	shib-keygen -o $KEYDIR -n sp-signing
	shib-keygen -o $KEYDIR -n sp-encrypt
else
	chown _shibd:_shibd $KEYDIR/sp-encrypt-cert.pem $KEYDIR/sp-encrypt-key.pem $KEYDIR/sp-signing-cert.pem $KEYDIR/sp-signing-key.pem
fi

envsubst < /tmp/shibboleth2.xml > /etc/shibboleth/shibboleth2.xml
augtool -s --noautoload --noload <<EOF
set /augeas/load/xml/lens "Xml.lns"
set /augeas/load/xml/incl "/etc/shibboleth/shibboleth2.xml"
load
defvar si /files/etc/shibboleth/shibboleth2.xml/SPConfig/ApplicationDefaults/Sessions/SessionInitiator[#attribute/id="$DEFAULT_LOGIN"]
set \$si/#attribute/isDefault "true"
EOF

if [ ! "x${SP_ERROR}" = "x" ]; then
augtool -s --noautoload --noload <<EOF
set /augeas/load/xml/lens "Xml.lns"
set /augeas/load/xml/incl "/etc/shibboleth/shibboleth2.xml"
load
defvar si /files/etc/shibboleth/shibboleth2.xml/SPConfig/ApplicationDefaults/Errors
set \$si/#attribute/redirectErrors "${SP_ERROR}"
EOF
fi

if [ -f /var/www/html/composer.json ]; then
	cd /var/www/html/
	composer install
fi

echo "----"
cat /etc/shibboleth/shibboleth2.xml
echo "----"
cat /etc/apache2/sites-available/default-ssl.conf

if [ ! -f "/etc/dehydrated/cert.pem" -o ! -f "/etc/dehydrated/privkey.pem" ]; then
	echo "Can't find cert.pem and privkey.pem in /etc/dehydrated"
fi

#mkdir -p /run/shibboleth
#/usr/sbin/shibd -f -c /etc/shibboleth/shibboleth2.xml -p /run/shibboleth/shibd.pid -w 30
mkfifo -m 600 /tmp/logpipe-shib
chown _shibd:_shibd /tmp/logpipe-shib
unbuffer cat /tmp/logpipe-shib &

service shibd start

rm -f /var/run/apache2/apache2.pid

env APACHE_LOCK_DIR=/var/lock/apache2 APACHE_RUN_DIR=/var/run/apache2 APACHE_PID_FILE=/var/run/apache2/apache2.pid APACHE_RUN_USER=www-data APACHE_RUN_GROUP=www-data APACHE_LOG_DIR=/var/log/apache2 apache2 -DFOREGROUND
