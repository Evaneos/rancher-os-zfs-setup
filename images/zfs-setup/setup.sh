#!/bin/sh

log () {
    echo "$(date +%Y-%m-%d-%H-%M-%S) $1"
}

log_error () {
    >&2 echo "$(date +%Y-%m-%d-%H-%M-%S) Error: $1"
}

log "Starting…"

tries=0
until system-docker exec console ls -l /sbin/zpool > /dev/null 2>&1
do
    tries=$((tries + 1))
    log "Waiting for ZFS binaries to be available… ($tries)"
    sleep 1

    if [ $tries -eq 60 ]; then
        log_error "Timed out after 60 seconds waiting for ZFS binaries"
        break
        exit 1
    fi
done

log "ZFS binaries available in console container"
system-docker exec console ls -l /sbin/zpool

log 'Checking ZFS mount sparse file…'
if [ ! -f /mnt/virtual.zfs ]; then

    pool_size=$(/dist/space.sh)
    log "no mount file, creating sparse file…"
    let "pool_size_blocks=$pool_size/1024"

    dd if=/dev/zero of=/mnt/virtual.zfs bs=1024 seek=$pool_size_blocks count=0
    log 'ZFS mount sparse file created'
fi

log 'Checking ZFS pool is available…'
if zpool list 2>&1 | grep -q 'no pools available'; then

    log 'Trying to import ZFS pool…'
    if zpool import zpool1 -f -d /mnt 2>&1 | grep -q 'no such pool available'; then
        log 'Creating ZFS pool…'
        zpool create zpool1 -m /mnt/zpool1 /mnt/virtual.zfs
        zfs create zpool1/docker
        log 'ZFS pool created'
    else
        log 'ZFS pool has been imported successfully'
    fi
else
    log 'ZFS pool is available. Nothing to do.'
fi

log 'ZFS pools'
zfs list

log 'Ensuring docker configuration'
ros config set rancher.docker.storage_driver 'zfs'
ros config set rancher.docker.graph /mnt/zpool1/docker

# We remove the duplicate & erroneous storage driver from the CLI arguments
# Cf. https://github.com/rancher/os/issues/1945#issuecomment-310897634
sed -i '/--storage-driver/d' /var/lib/rancher/conf/docker
log 'Docker configuration (re-)applied'

log 'Stopping docker daemon…'
system-docker stop docker || true
log 'Docker daemon stopped'

log 'Cleaning up former storage data files…'
rm -rf /var/lib/docker/* || true
log 'Cleaned up former storage data files'

log 'Starting docker daemon…'
system-docker start docker
log 'Docker daemon Started'
