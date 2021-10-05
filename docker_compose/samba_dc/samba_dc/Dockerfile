FROM alpine:3.14
LABEL maintainer="Hailong"

ENV SMABA_ALLOW_DNS_UPDATES=secure \
  SMABA_DNS_FORWARDER= \
  SAMBA_BIND_INTERFACES_ONLY=no \
  SAMBA_DOMAIN_ACTION=provision \
  SAMBA_DOMAIN_MASTER=auto \
  SAMBA_INTERFACES= \
  SAMBA_LOG_LEVEL=1 \
  SAMBA_MODEL=standard \
  SAMBA_NETBIOS_NAME= \
  SAMBA_REALM= \
  SAMBA_SERVER_STRING="Samba Domain Controller" \
  TZ=UTC \
  SAMBA_WORKGROUP= \
  LDB_MODULES_PATH=/usr/lib/samba/ldb/

ARG SAMBA_VERSION=4.14.5-r0

RUN apk add --update --no-cache ldb-tools samba-dc=$SAMBA_VERSION samba-winbind-clients \
  bind bind-libs bind-tools krb5 libcrypto1.1 libxml2 tzdata gettext

COPY *.conf.j2 /root/
COPY entrypoint.sh structure.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/entrypoint.sh \
  & chmod 0755 /usr/local/bin/structure.sh

VOLUME /etc/samba /var/lib/samba
EXPOSE 53 53/udp 88 88/udp 135 137-138/udp 139 389 389/udp 445 464 464/udp 636 3268-3269 49152-65535

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]