#!/bin/bash

# Red Hat Enterprise Linux 8 
docker pull registry.access.redhat.com/ubi8/ubi-minimal
docker pull registry.access.redhat.com/ubi8/ubi
docker pull registry.access.redhat.com/ubi8/ubi-init
docker run --privileged --name ubi-init -d --rm registry.access.redhat.com/ubi8/ubi-init

# Red Hat Enterprise Linux 9
docker pull registry.access.redhat.com/ubi9/ubi-minimal
docker pull registry.access.redhat.com/ubi9/ubi
docker pull registry.access.redhat.com/ubi9/ubi-init

# Centos Stream 9
docker image pull quay.io/centos/centos:stream9 
docker run --privileged --name centos-stream9 -d --rm quay.io/centos/centos:stream9
docker exec -it centos-stream9 /bin/bash
dnf install -y systemd
systemctl enable --now systemd

# Ubuntu 20.04 (Focal)
docker pull ubuntu:20.04
docker run --privileged --name ubuntu-focal -d --rm ubuntu:20.04 sleep infinity
docker exec -it ubuntu-focal /bin/bash



