#!/bin/sh

echo "Applying for a certificate"
if ! [ lego -a -m=$LEGO_EMAIL --domains $BASE_DOMAIN --domains *.$BASE_DOMAIN --dns $LEGO_DNS_PROVIDER --dns.resolvers $LEGO_DNS_SERVER --path /certs --pem renew --days 30 ]; then
  lego -a -m=$LEGO_EMAIL --domains $BASE_DOMAIN --domains *.$BASE_DOMAIN --dns $LEGO_DNS_PROVIDER --dns.resolvers $LEGO_DNS_SERVER --path /certs --pem  run
fi