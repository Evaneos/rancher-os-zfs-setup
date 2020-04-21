#!/bin/sh

set -euo pipefail

log () {
   >&2 echo "$(date +%Y-%m-%d-%H-%M-%S) $1"
}

# current available space
left_space=$(df -t overlay -P -B1 | tail -n +2 | awk '{ print $4 }')
human_left_space=$(numfmt --from=auto $left_space --to=iec-i)

log "$human_left_space space left on main overlay FS"

# lecture de la config
pool_size=$(
    numfmt --from=auto $(
        yq read /var/lib/rancher/conf/cloud-config.yml rancher.zfs_setup.pool_size -D 0
    ) 2>/dev/null || echo 0
)
human_pool_size=$(numfmt --from=auto $pool_size --to=iec-i)

if [ "$pool_size" -eq 0 ]; then
    # default size = left space - 2Gi
    let "pool_size=$left_space - (2 * 1024 * 1024 * 1024)" || true
    human_pool_size=$(numfmt --from=auto $pool_size --to=iec-i)

    log "Warning: No valid value found in rancher config rancher.zfs_setup.pool_size."
    log "         Configure the pool size via: ros config set rancher.zfs_setup.pool_size 1Gi"
    log "Warning: default value: $human_pool_size (left space - 2Gi)"
else
    log "Using rancher config pool size: $human_pool_size"
fi

if [ "$pool_size" -gt "$left_space" ]; then
    log "Error: cannot create ZFS pool with of size $human_pool_size: you only have $human_left_space left space."
    log "       Please provide a lower and explicit ZFS pool size."
    log "       Configure the pool size via: ros config set rancher.zfs_setup.pool_size 1Gi"
    exit 1
fi

minimum_pool_size=$(numfmt --from=auto 64Mi)
if [ "$pool_size" -lt $minimum_pool_size ]; then
    log "Error: cannot create ZFS pool with of size $human_pool_size: ZFS pool needs a minimum size of 64Mi"
    exit 1
fi

echo $pool_size
