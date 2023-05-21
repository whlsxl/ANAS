#!/bin/sh

echo "Setting DNS server to $LEGO_DNS_SERVER"
echo "nameserver $LEGO_DNS_SERVER" > /etc/resolv.conf
echo "Applying for a certificate"
$( /lego -a -m=$LEGO_EMAIL --domains $BASE_DOMAIN --domains *.$BASE_DOMAIN --path /certs --pem --dns $DNS_PROVIDER --dns.resolvers $LEGO_DNS_SERVER renew --days 30 )
RESULT=$?
if [ $RESULT != 0 ]; then
  $( /lego -a -m=$LEGO_EMAIL --domains $BASE_DOMAIN --domains *.$BASE_DOMAIN --path /certs --pem --dns $DNS_PROVIDER --dns.resolvers $LEGO_DNS_SERVER run )
fi