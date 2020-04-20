FROM docker:latest

COPY zfs-utils /bin/zpool
COPY zfs-utils /bin/zfs

COPY setup.sh /dist/
COPY entrypoint.sh /dist/

CMD ["/dist/setup.sh"]

ENTRYPOINT ["/dist/entrypoint.sh"]
