INITIAL_ISO_PATH=$1
IGNITION_PATH=$2
FINAL_ISO_PATH=$3
EXTRA_FOLDER=${4:-""}

CONFIG_PATH=$(dirname "$0")

if [ -z "$1" ]
  then
    echo "Please provide the initial ISO"
    exit 1
fi

if [ -z "$2" ]
  then
    echo "Please provide the ignition file to inject"
    exit 1
fi

if [ -z "$3" ]
  then
    echo "Please provide the path for final ISO"
    exit 1
fi

if [ -z "$4" ]
  then
    echo "No extra folder found, will be running without extra config"
fi
exit 1

echo "***** WARNING: this script needs to be executed as root *********"

# create initial directories
umount /mnt/custom_live_iso || true
rm -rf /mnt/custom_live_iso || true
mkdir /mnt/custom_live_iso || true

rm -rf /tmp/modified_iso || true
mkdir /tmp/modified_iso || true
chown 777 /tmp/modified_iso || true

# mount the installer iso
echo "mount -t iso9660 -o loop $INITIAL_ISO_PATH  /mnt/custom_live_iso"
mount -t iso9660 -o loop $INITIAL_ISO_PATH  /mnt/custom_live_iso

# copy to a temporary directory
pushd /mnt/custom_live_iso
tar cf - . | (cd /tmp/modified_iso && tar xfp -)
popd

# generate the extra ramdisk
bash $CONFIG_PATH/ramdisk_generator.sh $IGNITION_PATH /tmp/modified_iso/images/ignition_ramdisk

# append parameter to isolinux.cfg
sed -i "/initrd=.*/c\  append initrd=/images/initramfs.img,\/images\/ignition_ramdisk nomodeset" /tmp/modified_iso/isolinux/isolinux.cfg

# rebuild ISO
pushd /tmp/modified_iso
mkisofs -v -l -r -J -o $FINAL_ISO_PATH -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table .
popd

# clean
umount /mnt/custom_live_iso
rm -rf /mnt/custom_live_iso
rm -rf /tmp/modified_iso

