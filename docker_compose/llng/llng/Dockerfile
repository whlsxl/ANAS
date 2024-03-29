ARG DISTRO=debian
ARG DISTRO_VARIANT=bookworm

FROM docker.io/tiredofit/nginx:${DISTRO}-${DISTRO_VARIANT}

LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ENV LEMONLDAP_VERSION=2.16.2 \
    NGINX_AUTHENTICATION_TYPE=NONE \
    NGINX_LISTEN_PORT=80 \
    NGINX_LOG_ACCESS_FORMAT=llng_standard \
    NGINX_ENABLE_CREATE_SAMPLE_HTML=FALSE \
    NGINX_USER=llng \
    NGINX_GROUP=llng \
    NGINX_LOG_ACCESS_LOCATION=/www/logs/http \
    NGINX_LOG_ACCESS_FILE=access.log \
    NGINX_LOG_BLOCKED_LOCATION=/www/logs/http \
    NGINX_LOG_ERROR_FILE=error.log \
    NGINX_LOG_ERROR_LOCATION=/www/logs/http \
    NGINX_SITE_ENABLED=null \
    LLNG_DEFAULTLOGGER=Lemonldap::NG::Common::Logger::Std  \
    PATH=/usr/share/lemonldap-ng/bin:${PATH} 

RUN source /assets/functions/00-container && \
    set -x && \
    addgroup --gid 2884 llng && \
    adduser --system --disabled-login --gid 2884 --uid 2884 --home /var/lib/lemonldap-ng/ llng && \
    \
    # Build Dependencies
    package update && \
    package upgrade && \
    package install \
    lemonldap-ng \
    lemonldap-ng-doc \
    cron \
    imagemagick \
    mariadb-client \
    postgresql-client \
    # mongo-c-driver \
    libauthen-sasl-perl \
    libauthen-webauthn-perl \
    libauthen-pam-perl \
    libcrypt-u2f-server-perl \
    libssl-dev \
    liblasso-perl \
    libdbd-mariadb-perl \
    libdbd-mysql-perl \
    libdbd-pg-perl \
    libapache-session-browseable-perl \
    libauthen-radius-perl \
    # libmongodb-perl \
    libauthcas-perl \
    libdatetime-format-rfc3339-perl \
    libapache-session-ldap-perl \
    # libapache-session-memcached-perl \
    # libapache-session-mongodb-perl \
    libdigest-hmac-perl \
    libconvert-base32-perl \
    libdigest-md5-perl \
    libdigest-sha-perl \
    libcgi-emulate-psgi-perl \
    libglib-perl \
    libio-pty-perl \
    libio-socket-timeout-perl \
    libio-string-perl \
    libnet-cidr-perl \
    libnet-cidr-lite-perl \
    libsoap-lite-perl \
    libcrypt-dh-gmp-perl \
    libextutils-pkgconfig-perl \
    libemail-simple-perl \
    libgd-securityimage-perl \
    libtest-differences-perl \
    liblog-log4perl-perl \
    libimage-magick-perl \
    # libmime-perl \
    libgssapi-perl \
    libgd-perl \
    curl \
    make \
    gcc \
    build-essential \
    && \
    \
    ### Install Perl Modules Manually not available in Repository
    ln -s /usr/bin/perl /usr/local/bin/perl && \
    curl -L http://cpanmin.us -o /usr/bin/cpanm && \
    chmod +x /usr/bin/cpanm && \
    cpanm -n \
    Clone \
    Apache::Session \
    Cache::Cache \
    Auth::Yubikey_WebClient \
    Authen::Radius \
    Authen::Captcha \
    Authen::WebAuthn \
    Authen::PAM \
    CGI::Compile \
    Config::IniFiles \
    Convert::PEM \
    Convert::Base32 \
    Cookie::Baker \
    Cookie::Baker::XS \
    Crypt::OpenSSL::Bignum \
    Crypt::OpenSSL::RSA \
    Crypt::OpenSSL::X509 \
    Crypt::U2F::Server::Simple \
    Crypt::Rijndael \
    Crypt::URandom \
    DateTime::Format::RFC3339 \
    DBI \
    Digest::HMAC_SHA1 \
    Digest::MD5 \
    Digest::SHA \
    Email::Sender \
    GD::SecurityImage \
    GSSAPI \
    HTML::Template \
    HTTP::Headers \
    HTTP::Request \
    IO::String \
    LWP::UserAgent \
    LWP::Protocol::https \
    MIME::Base64 \
    MIME::Entity \
    Mouse \
    # MongoDB \
    Net::Facebook::Oauth2 \
    Net::CIDR \
    Net::LDAP \
    Net::OAuth \
    Net::OpenID::Common \
    Net::SMTP \
    Net::SSLeay \
    Regexp::Assemble \
    Regexp::Common \
    Plack \
    Redis \
    Cache::Memcached \
    Sentry::Raven \
    String::Random \
    Unicode::String \
    Text::Unidecode \
    Time::Fake \
    URI \
    URI::Escape \
    Web::ID \
    YAML \
    JSON \
    && \
    # Shuffle some Files around
    mkdir -p /assets/llng/conf && \
    mv /etc/lemonldap-ng/lemonldap-ng.ini /assets/llng/conf/ && \
    mkdir -p /var/run/llng-fastcgi-server && \
    chown -R llng /var/run/llng-fastcgi-server && \
    ln -s /usr/share/lemonldap-ng/doc /usr/share/lemonldap-ng/manager/doc && \
    ln -s /usr/share/lemonldap-ng/portal /usr/share/lemonldap-ng/portal/htdocs && \
    # Cleanup
    rm -rf \
    /root/.bash_history \
    /root/.cache \
    /root/.config \
    /root/.cpanm \
    # /var/lib/lemonldap-ng/conf/* \
    /etc/fail2ban/jail.d/* \
    /tmp/* \
    && \
    package cleanup && \
    deluser nginx


COPY root /