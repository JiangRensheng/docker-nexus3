#!/bin/sh

DOCKER_REP="/docker/repository"

sudo mdadm -Dsv 2>/dev/null >/dev/null
sudo pvscan 2>&1 >/dev/null && sudo vgscan 2>&1 >/dev/null && sudo lvscan 2>&1 >/dev/null

VG_RAID="$(sudo pvscan  | grep '/dev/md' | awk '{print $4}')"
[ "x$VG_RAID" != "x" ] && LV_RAID="$(sudo lvscan 2>/dev/null | grep "${VG_RAID}" | awk -F\' '{print $2}')"
mkdir -p ${DOCKER_REP}

[ "x$LV_RAID" != "x" ] && sudo mount ${LV_RAID} ${DOCKER_REP}

# ToDo: mount all points

${NEXUS_HOME}/bin/nexus run

sudo umount "${DOCKER_REP}" 2>/dev/null

