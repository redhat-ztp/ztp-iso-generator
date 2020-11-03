INITIAL_ISO_PATH=$1
CONFIG_FOLDER=$2
FINAL_ISO_PATH=$3

CONFIG_PATH=$(dirname "$0")

if [ -z "$1" ]
  then
    echo "Please provide the initial ISO"
    exit 1
fi

if [ -z "$2" ]
  then
    echo "Please provide the config folder to inject"
    exit 1
fi

if [ -z "$3" ]
  then
    echo "Please provide the path for final ISO"
    exit 1
fi

echo "***** WARNING: this script needs to be executed as root *********"

# create initial directories
umount /mnt/custom_live_iso
rm -rf /mnt/custom_live_iso
mkdir /mnt/custom_live_iso

rm -rf /tmp/modified_iso
mkdir /tmp/modified_iso
chown 777 /tmp/modified_iso

# mount the installer iso
echo "mount -t iso9660 -o loop $INITIAL_ISO_PATH  /mnt/custom_live_iso"
mount -t iso9660 -o loop $INITIAL_ISO_PATH  /mnt/custom_live_iso

# copy to a temporary directory
pushd /mnt/custom_live_iso
tar cf - . | (cd /tmp/modified_iso && tar xfp -)
popd

# copy the custom isolinux.cfg
cp ${CONFIG_PATH}/isolinux.cfg /tmp/modified_iso/isolinux/

# generate extra folder with our config
mkdir /tmp/modified_iso/config
cp -R $CONFIG_FOLDER/* /tmp/modified_iso/config/

pushd /tmp/modified_iso
rm -rf images/pxeboot/*

# rebuild ISO
mkisofs -o $FINAL_ISO_PATH -b isolinux/isolinux.bin -c isolinux/boot.cat  -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -V "Red-Hat-Enterprise-Linux-8-2-x86" .
popd

# clean
umount /mnt/custom_live_iso
rm -rf /mnt/custom_live_iso
rm -rf /tmp/modified_iso

