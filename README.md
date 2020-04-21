[![docker image](https://img.shields.io/badge/docker-evaneos%2Francher--os--zfs--setup-blue?style=flat-square&logo=docker)](https://hub.docker.com/repository/docker/evaneos/rancher-os-zfs-setup)

# RancherOS ZFS setup

This RancherOS system service bootstraps a single ZFS pool and import it on system start.

## Getting started

### Install ZFS

```shell
sudo ros service enable zfs
sudo ros service up zfs
# It might take some time (10 to 20 minutes)
# You can follow the progress of the build, in another session, via:
sudo ros service logs --follow zfs
# Check ZFS is enabled
lsmod | grep zfs
```

### Install & run the service

```shell
sudo ros config set rancher.repositories.zfs-setup.url https://raw.githubusercontent.com/Evaneos/rancher-os-zfs-setup/v0.1.0
sudo ros service enable zfs-setup
sudo ros service up zfs-setup
# You can follow the progress of the setup, in another session, via:
sudo ros service logs --follow zfs-setup
```

## Use case

This service has been created for `docker-machine` in order to use ZFS and its snapshot and versioning capabilities on a local machine.

## Why?

The official documentation about [using ZFS on RancherOS](https://rancher.com/docs/os/v1.x/en/storage/using-zfs/) is cumbersome and quite incomplete.

Furthermore, the specific needs of a local `docker-machine` are not covered:
- creating a ZFS pool from a file (since we cannot use a block device)
- making the ZFS pool persistent across restarts

Note that, however, `docker-machine` is in [maintenance mode](https://github.com/docker/machine/issues/4537).

## Workflow

This service has 2 flows: the setup and the import/start.

The setup is run the first time to create the ZFS pool.

The import/start is run every time the machine starts in order to import and mount the ZFS pool.

## Configuration

You can customize a few element used by the service.

Note the _Setup only_ column: if `yes`, the configuration element will only be used when setting up the ZFS pool.

| Path                          | Type                                    | Default          | Setup only |
|-------------------------------|-----------------------------------------|------------------|------|
| `rancher.zfs_setup.pool_size` | `numfmt` compliant value<br/>eg. `25Gi` | Left space - 2Gi | yes |

## Disclaimer

This service is solely thought for `docker-machine` and does not aim to fit other needs for now.

## Troubleshooting

### Unable to verify the Docker daemon is listening

```shell
# [...]
Detecting the provisioner...
Unable to verify the Docker daemon is listening: Maximum number of retries (10) exceeded
```

In general, you just have to wait a bit (30 seconds to 1 minute) and the docker daemon will then start.

Per RancherOS and its ZFS design, importing the ZFS pool and starting the docker service can take some time. As a matter of fact, if `docker-machine` allowed 1 or 2 more retries, this would not be an issue.

## References

- [Using ZFS](https://rancher.com/docs/os/v1.x/en/storage/using-zfs/) [official docs]
- [System services](https://rancher.com/docs/os/v1.x/en/system-services/) [official docs]
- [Rancher OS core services](https://github.com/rancher/os-services) [github]
- [Conflict between ZFS storage & overlay driver](https://github.com/rancher/os/issues/1945) [github issue]
