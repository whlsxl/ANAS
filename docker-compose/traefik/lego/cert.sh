#!/bin/sh

echo "Applying for a certificate"
if ! [ lego -a -m "$TRAEFIK_LEGO_EMAIL" --domains "$BASE_URL" --domains "*.$BASE_URL" --path="/certs" -pem --dns "$TRAEFIK_LEGO_DNS_PROVIDER" renew --days 30 ]; then
  lego -a -m "$TRAEFIK_LEGO_EMAIL" --domains "$BASE_URL" --domains "*.$BASE_URL" --path="/certs" -pem --dns "$TRAEFIK_LEGO_DNS_PROVIDER" run
fi
