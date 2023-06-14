#!/bin/bash

set -x
IPv4_TALK_ALLOW_ADDRESSES=""
ips=$(ip addr show | grep 'inet ' | awk '{print $2}' | cut -d '/' -f1)
for ip in $ips; do
  if [ "$ip" != "127.0.0.1" ]; then
    IPv4_TALK_ALLOW_ADDRESSES="$IPv4_TALK_ALLOW_ADDRESSES\nallowed-peer-ip=$ip"
  fi
done
set +x

# Turn
cat << TURN_CONF > "/etc/turnserver.conf"
listening-port=$NEXTCLOUD_TALK_TURN_PORT
fingerprint
use-auth-secret
static-auth-secret=$TALK_TURN_SECRET
realm=$NEXTCLOUD_DOMAIN
total-quota=0
bps-capacity=0
stale-nonce
no-multicast-peers
simple-log
pidfile=/var/tmp/turnserver.pid
userdb=/var/lib/turn/turndb
# Based on https://nextcloud-talk.readthedocs.io/en/latest/TURN/#turn-server-and-internal-networks
$(echo -e $IPv4_TALK_ALLOW_ADDRESSES)
denied-peer-ip=0.0.0.0-0.255.255.255
denied-peer-ip=10.0.0.0-10.255.255.255
denied-peer-ip=100.64.0.0-100.127.255.255
denied-peer-ip=127.0.0.0-127.255.255.255
denied-peer-ip=169.254.0.0-169.254.255.255
denied-peer-ip=172.16.0.0-172.31.255.255
denied-peer-ip=192.0.0.0-192.0.0.255
denied-peer-ip=192.0.2.0-192.0.2.255
denied-peer-ip=192.88.99.0-192.88.99.255
denied-peer-ip=192.168.0.0-192.168.255.255
denied-peer-ip=198.18.0.0-198.19.255.255
denied-peer-ip=198.51.100.0-198.51.100.255
denied-peer-ip=203.0.113.0-203.0.113.255
denied-peer-ip=240.0.0.0-255.255.255.255
TURN_CONF

# Signling
cat << SIGNALING_CONF > "/etc/signaling.conf"
[http]
listen = 0.0.0.0:8081

[app]
debug = false

[sessions]
hashkey = $(openssl rand -hex 16)
blockkey = $(openssl rand -hex 16)

[clients]
internalsecret = $(openssl rand -hex 16)

[backend]
backends = backend-1
allowall = false
timeout = 10
connectionsperhost = 8

[backend-1]
url = ${NEXTCLOUD_DOMAIN_FULL}
secret = ${TALK_SIGNALING_SECRET}

[nats]
url = nats://127.0.0.1:4222

[mcu]
type = janus
url = ws://127.0.0.1:8188
SIGNALING_CONF

exec "$@"