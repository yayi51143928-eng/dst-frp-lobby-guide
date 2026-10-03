FROM alpine:3.22
RUN apk add --no-cache openssh-client-default curl ca-certificates
COPY tunnel.sh /usr/local/bin/dst-proxy-tunnel
RUN chmod 755 /usr/local/bin/dst-proxy-tunnel
ENTRYPOINT ["/usr/local/bin/dst-proxy-tunnel"]
