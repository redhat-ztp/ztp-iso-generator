# Generates a minimal RHCOS ISO, that will pull rootfs from external source
FINAL_ISO_PATH=$1
KERNEL_URL=${2:-https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.6/latest/rhcos-live-kernel-x86_64}
RAMDISK_URL=${3:-https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.6/latest/rhcos-live-initramfs.x86_64.img}

CONFIG_PATH=$(dirname "$0")

if [ -z "$1" ]
  then
    echo "Please provide the initial ISO"
    exit 1
fi

rm -rf /tmp/coreos
rm -f $FINAL_ISO_PATH

pushd /tmp
mkdir -p coreos/{isolinux,syslinux,coreos}

pushd /tmp/coreos/coreos

# get kernel
curl $KERNEL_URL -o vmlinuz

# get ramdisk
curl $RAMDISK_URL -o initramfs.img
popd

# get syslinux
if [[ ! -f /tftpboot/chain.c32 ]]; then
  echo "Missing syslinux package. Attempting installation."
  dnf -y install syslinux syslinux-tftpboot || true
fi

if [[ ! -f /tftpboot/chain.c32 ]]; then
    # package may have failed, use curl
    curl -O https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
    tar -xzvf syslinux-6.03.tar.gz
    cp syslinux-6.03/bios/com32/chain/chain.c32 coreos/syslinux/
    cp syslinux-6.03/bios/com32/lib/libcom32.c32 coreos/syslinux/
    cp syslinux-6.03/bios/com32/libutil/libutil.c32 coreos/syslinux/
    cp syslinux-6.03/bios/memdisk/memdisk coreos/syslinux/
    cp syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 coreos/isolinux/
    cp syslinux-6.03/bios/core/isolinux.bin coreos/isolinux/
else
    cp /tftpboot/chain.c32 coreos/syslinux/
    cp /tftpboot/libcom32.c32 coreos/syslinux/
    cp /tftpboot/libutil.c32 coreos/syslinux/
    cp /tftpboot/memdisk coreos/syslinux/
    cp /tftpboot/ldlinux.c32 coreos/isolinux/
    cp /usr/share/syslinux/isolinux.bin coreos/isolinux/
fi

pushd coreos

cat <<EOF >> syslinux/isolinux.cfg
INCLUDE /syslinux/syslinux.cfg

prompt 0
default coreos

TIMEOUT 50
LABEL coreos
KERNEL /coreos/vmlinuz
APPEND initrd=/coreos/initramfs.img
EOF

# generate the ISO
mkisofs -v -l -r -J -o $FINAL_ISO_PATH -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table .
echo "Image generated at $FINAL_ISO_PATH"

popd
