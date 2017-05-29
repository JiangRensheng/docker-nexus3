#!/bin/sh

DOCKER_REP="/docker/repository"

mdadm -Dsv 2>/dev/null >/dev/null
pvscan 2>&1 >/dev/null && vgscan 2>&1 >/dev/null && lvscan 2>&1 >/dev/null

VG_RAID="$(pvscan  | grep '/dev/md' | awk '{print $4}')"
[ "x$VG_RAID" != "x" ] && LV_RAID="$(lvscan 2>/dev/null | grep "${VG_RAID}" | awk -F\' '{print $2}')"
mkdir -p ${DOCKER_REP}

[ "x$LV_RAID" != "x" ] && mount ${LV_RAID} ${DOCKER_REP}

# ToDo: mount all points

${NEXUS_HOME}/bin/nexus run

umount "${DOCKER_REP}" 2>/dev/null

