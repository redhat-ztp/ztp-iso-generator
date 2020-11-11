IGNITION_FOLDER=$1
RAMDISK_PATH=$2

if [ -z "$1" ]
  then
    echo "Please provide the ignition file"
    exit 1
fi

if [ -z "$2" ]
  then
    echo "Please provide the config the ramdisk path"
    exit 1
fi

echo "Building ramdisk $RAMDISK_PATH ..."
pushd $IGNITION_FOLDER
find . | sed 's/^[.]\///' | cpio -o -H newc -R root --no-absolute-filenames > $RAMDISK_PATH
popd
