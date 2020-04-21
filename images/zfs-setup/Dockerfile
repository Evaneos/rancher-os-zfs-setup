FROM docker:latest

LABEL maintainer="infra@evaneos.com"
LABEL vendor="Evaneos"

RUN wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64" \
    && chmod +x /usr/local/bin/yq

RUN apk add --no-cache coreutils

COPY zfs-utils /bin/zpool
COPY zfs-utils /bin/zfs

COPY setup.sh space.sh /dist/

CMD ["/dist/setup.sh"]

ENTRYPOINT ["/usr/bin/ros", "entrypoint"]
