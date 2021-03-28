#!/bin/sh

echo "Applying for a certificate"
if ! [ lego -a -m "${TRAEFIK_LEGO_EMAIL}" --domains "$BASE_DOMAIN" --domains "*.$BASE_DOMAIN" --path="/certs" --pem --dns "$TRAEFIK_LEGO_DNS_PROVIDER" --dns.resolvers "$TREAFIK_LEGO_DNS_SERVER" renew --days 30 ]; then
  lego -a -m "${TRAEFIK_LEGO_EMAIL}" --domains "$BASE_DOMAIN" --domains "*.$BASE_DOMAIN" --path="/certs" --pem --dns "$TRAEFIK_LEGO_DNS_PROVIDER" --dns.resolvers "$TREAFIK_LEGO_DNS_SERVER" run
fi