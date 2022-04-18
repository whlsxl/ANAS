FROM ghcr.io/linuxserver/baseimage-ubuntu:focal AS wsdd2-builder

ARG CHINESE_SPEEDUP

RUN if [ "$CHINESE_SPEEDUP" = "true" ] ; then  \
  sed -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list; \
  fi
RUN apt-get update \
  && apt-get install -y \
  make \
  gcc \
  linux-libc-dev \
  linux-headers-$(uname -r) \
  wget \
  && wget -O - https://github.com/whlsxl/wsdd2/archive/refs/heads/master.tar.gz | tar zxvf - \
  && cd wsdd2-master && make

FROM ghcr.io/linuxserver/baseimage-ubuntu:focal
LABEL maintainer="Hailong"

ENV DEBIAN_FRONTEND noninteractive

COPY --from=wsdd2-builder /wsdd2-master/wsdd2 /usr/sbin

ARG CHINESE_SPEEDUP
RUN if [ "$CHINESE_SPEEDUP" = "true" ] ; then  \
  sed -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list; \
  fi
RUN apt-get update \
  && apt-get install -y \
  avahi-daemon \
  samba \
  smbclient \
  winbind \
  libpam-winbind \
  libnss-winbind \
  krb5-kdc \
  libpam-krb5 \
  ldb-tools \
  gettext \
  iproute2 \
  && apt-get clean \
  && rm -rf \
  /tmp/* \
  /var/lib/apt/lists/* \
  /var/tmp/* \
  /var/log/* \
  && sed -i 's/#enable-dbus=.*/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf \
  && rm -vf /etc/avahi/services/*

COPY root/ /

EXPOSE 139 445


# HEALTHCHECK CMD ["/container/scripts/docker-healthcheck.sh"]