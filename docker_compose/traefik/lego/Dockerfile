FROM goacme/lego:v3.4.0

WORKDIR /certs

COPY cert.sh /etc/periodic/weekly/
COPY run.sh /root/
RUN chmod +x /root/run.sh /etc/periodic/weekly/cert.sh

ENTRYPOINT [ "/root/run.sh" ]