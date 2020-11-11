AI_ISO_PATH=$1
FINAL_IGNITION_PATH=$2

CONFIG_PATH=$(dirname "$0")

if [ -z "$1" ]
  then
    echo "Please provide the Assisted Installer ISO path"
    exit 1
fi

# create initial directories
umount /mnt/discovery_iso || true
rm -rf /mnt/discovery_iso || true
mkdir /mnt/discovery_iso

# mount the discovery iso
mount -t iso9660 -o loop $AI_ISO_PATH  /mnt/discovery_iso

# extract the ignition file and copy to a temporary directory
rm -rf /tmp/temporary_ignition
mkdir /tmp/temporary_ignition
cp /mnt/discovery_iso/images/ignition.img /tmp/temporary_ignition/

# extract the file
pushd /tmp/temporary_ignition
mv ignition.img ignition.img.xz
unxz ignition.img.xz

# extract with cpio
cpio -idmv < ignition.img

# copy to final file
cp config.ign  $FINAL_IGNITION_PATH
popd

echo "Your ignition file is on $FINAL_IGNITION_PATH"

# cleanup system
rm -rf /tmp/temporary_ignition

umount /mnt/discovery_iso
rm -rf /mnt/discovyer_iso
