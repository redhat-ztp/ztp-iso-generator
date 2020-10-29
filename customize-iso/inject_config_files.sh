INITIAL_ISO_PATH=$1
CONFIG_FOLDER=$2
FINAL_ISO_PATH=$3

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

# open the iso and mount it
mkdir /tmp/temporary_iso
mount -t iso9660 -o loop $INITIAL_ISO_PATH /mnt/

pushd /mnt
tar cf - . | (cd /tmp/temporary_iso; tar xfp -)
popd

# create new config folder and inject files
mkdir -p /tmp/temporary_iso/opt/config
cp -R $2 /tmp/temporary_iso/opt/config/

pushd /tmp/temporary_iso
mkisofs -o $FINAL_ISO_PATH -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V "Installer ISO" .
popd

