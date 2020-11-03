# Generates a minimal RHCOS ISO, that will pull rootfs from external source
pushd /tmp
mkdir -p coreos/{isolinux,syslinux,coreos}

pushd /tmp/coreos/coreos

# get kernel
curl -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.6/latest/rhcos-live-kernel-x86_64
mv rhcos-live-kernel-x86_64 vmlinuz

# get ramdisk
curl -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.6/latest/rhcos-live-initramfs.x86_64.img
mv rhcos-live-initramfs.x86_64.img initramfs.img
popd

# get syslinux
curl -O https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
tar -xzvf syslinux-6.03.tar.gz
cp syslinux-6.03/bios/com32/chain/chain.c32 coreos/syslinux/
cp syslinux-6.03/bios/com32/lib/libcom32.c32 coreos/syslinux/
cp syslinux-6.03/bios/com32/libutil/libutil.c32 coreos/syslinux/
cp syslinux-6.03/bios/memdisk/memdisk coreos/syslinux/
cp syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 coreos/isolinux/
cp syslinux-6.03/bios/core/isolinux.bin coreos/isolinux/

pushd coreos

cat <<EOF >> syslinux/isolinux.cfg
INCLUDE /syslinux/syslinux.cfg

prompt 0
default coreos

LABEL coreos
KERNEL /coreos/vmlinuz
APPEND initrd=/coreos/initramfs.img root=/dev/ram0 state=tmpfs:
cat: +: No existe el fichero o el directorio
[yolanda@localhost tmp]$ cat coreos/isolinux.cfg
INCLUDE /syslinux/syslinux.cfg

prompt 0
default coreos

LABEL coreos
KERNEL /coreos/vmlinuz
APPEND initrd=/coreos/initramfs.img root=##REPLACE## state=tmpfs:
EOF

# generate the ISO
mkisofs -v -l -r -J -o ../coreos.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table .
