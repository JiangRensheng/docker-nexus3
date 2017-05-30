#!/bin/sh

# docker run -it --rm --privileged -v /dev/vgraid/lvol0:/dev/nexus --name nexus deepsecs/nexus3_lvm

# ENV NEXUS_VOLUMN="/dev/nexus"

sudo mount ${NEXUS_VOLUMN} /mnt && \
sudo mount -o bind /mnt/${NEXUS_DATA} ${NEXUS_DATA}

${NEXUS_HOME}/bin/nexus run

sudo umount ${NEXUS_DATA} /mnt

