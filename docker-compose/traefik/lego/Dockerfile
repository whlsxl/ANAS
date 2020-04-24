FROM goacme/lego:v3.4.0

WORKDIR /certs

COPY cert.sh /etc/periodic/weekly/

ENTRYPOINT [ "crond", "-l", "2", "-f" ]