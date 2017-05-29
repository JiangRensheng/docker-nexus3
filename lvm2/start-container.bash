#!/bin/sh

# ENV NEXUS_VOLUMN="/dev/nexus"

sudo mount ${NEXUS_VOLUMN} /mnt

if [ $? -eq 0 ]; then

  if [ ! -d /mnt/${NEXUS_DATA} ]; then
    # nexus directory not exist, create and copy from $NEXUS_DATA
    sudo cp ${NEXUS_DATA} /mnt -R
    sudo chown nexus:nexus /mnt${NEXUS_DATA}/* -R
  fi

  sudo mount -o bind /mnt${NEXUS_DATA} ${NEXUS_DATA}

fi

sudo chown -R nexus:nexus ${NEXUS_DATA}

${NEXUS_HOME}/bin/nexus run

sudo umount /mnt ${NEXUS_DATA}

