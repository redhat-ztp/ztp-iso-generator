# Lorax Composer Live ISO output kickstart template

# Firewall configuration
firewall --disabled

# X Window System configuration information
#xconfig  --startxonboot
skipx

# Root password is removed for live-iso
#rootpw --iscrypted $6$FixQJM2sOJCUGtC2$4LQpdSCPyt836aNlyjosh4WeS7AEn2WNeT2KZLng4T34ma.4.d7Q6ZUj2GXuOu.y6eBPVmeKaYnRKU4Zw3Mit1
# Network information
network  --bootproto=dhcp --device=link --activate
# NOTE: keyboard and lang can be replaced by blueprint customizations.locale settings
# System keyboard
keyboard --xlayouts=us --vckeymap=us
# System language
lang en_US.UTF-8
# SELinux configuration (disabled)
selinux --disabled
# Installation logging level
logging --level=info
# Shutdown after installation
shutdown
# System services
services --disabled="network,sshd" --enabled="NetworkManager"
# System bootloader configuration
bootloader --location=none

%post

echo nameserver 8.8.8.8 > /etc/resolv.conf

# dowload coreos image
#podman pull quay.io/coreos/coreos-installer:latest

# allow sudo without password
sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers

# don't use prelink on a running live image
sed -i 's/PRELINKING=yes/PRELINKING=no/' /etc/sysconfig/prelink &>/dev/null || true

# enable tmpfs for /tmp
systemctl enable tmp.mount

rm -f /var/lib/rpm/__db*

# Remove random-seed
rm /var/lib/systemd/random-seed

# Remove the rescue kernel and image to save space
# Installation will recreate these on the target
rm -f /boot/*-rescue*
rm -f /boot/System.map*

# remove some random help txt files
rm -fv /usr/share/gnupg/help*.txt || true
rm -rf /usr/share/man/*
# Pruning random things
rm /usr/lib/rpm/rpm.daily || true
rm -rfv /usr/lib64/nss/unsupported-tools/ || true
# Statically linked crap
rm -fv /usr/sbin/{glibc_post_upgrade.x86_64,sln} || true
#some random not-that-useful binaries
rm -fv /usr/bin/pinky || true
rm -rfv  /usr/share/zoneinfo || true
# don't need icons
rm -rfv /usr/share/icons/* || true

dnf autoremove -y

# Remove some dnf info
rm -rfv /var/lib/dnf || true

# Final pruning
rm -rfv /var/cache/* /var/log/* /tmp/* || true

# Kernel modules minimization
# Drop many filesystems
rpm -rf /lib/modules/*/kernel/fs || true
rpm -rf /lib/modules/*/kernel/sound || true

# Drop some unused rpms, without dropping dependencies
rpm -e --nodeps checkpolicy || true
rpm -e --nodeps dmraid-events || true
rpm -e --nodeps gamin || true
rpm -e --nodeps gnupg2 || true
rpm -e --nodeps linux-atm-libs || true
rpm -e --nodeps make || true
rpm -e --nodeps mtools || true
rpm -e --nodeps mysql-libs || true
rpm -e --nodeps perl || true
rpm -e --nodeps perl-Module-Pluggable || true
rpm -e --nodeps perl-Net-Telnet || true
rpm -e --nodeps perl-PathTools || true
rpm -e --nodeps perl-Pod-Escapes  || true
rpm -e --nodeps perl-Pod-Simple || true
rpm -e --nodeps perl-Scalar-List-Utils || true
rpm -e --nodeps perl-hivex || true
rpm -e --nodeps perl-macros || true
rpm -e --nodeps sgpio || true
rpm -e --nodeps syslinux || true
rpm -e --nodeps system-config-firewall-base || true
rpm -e --nodeps usermode || true
rpm -e --nodeps libusbx || true
rpm -e --nodeps libdnf || true
rpm -e --nodeps cronie || true
rpm -e --nodeps cronie-anacron || true
rpm -e --nodeps dracut-squash || true
rpm -e --nodeps rpm-plugin-selinux || true
rpm -e --nodeps python3-rhn-client-tools || true
rpm -e --nodeps rhn-client-tools || true
rpm -e --nodeps rhn-check || true
rpm -e python3-rhn-check || true
rpm -e --nodeps dnf-plugin-spacewalk || true
rpm -e python3-dnf-plugin-spacewalk || true
rpm -e yum || true
rpm -e dnf || true
rpm -e dnf-plugins-core || true
rpm -e python3-dnf-plugins-core || true
rpm -e --nodeps linux-firmware || true

# Ensure we don't have the same random seed on every image, which
# could be bad for security at a later point...
echo " * purge existing random seed to avoid identical seeds everywhere"
rm -f /var/lib/random-seed

# This seems to cause 'reboot' resulting in a shutdown on certain platforms
# See https://tickets.puppetlabs.com/browse/RAZOR-100
echo " * remove intel mei modules"
irm -rf /lib/modules/*/kernel/drivers/misc/mei || true

# See https://bugzilla.redhat.com/show_bug.cgi?id=1335830
echo " * remove some video drivers to prevent kexec isues"
rm -rf /lib/modules/*/kernel/drivers/gpu/drm \
  /lib/modules/*/kernel/drivers/video/fbdev \
  /lib/firmware/{amdgpu,radeon} || true

echo " * remove unused drivers (sound, media, nls, fs, wifi)"
rm -rf /lib/modules/*/kernel/sound \
  /lib/modules/*/kernel/drivers/{media,hwmon,watchdog,rtc,input/joystick,bluetooth,edac} \
  /lib/modules/*/kernel/net/{atm,bluetooth,sched,sctp,rds,l2tp,decnet} \
  /lib/modules/*/kernel/fs/{nls,ocfs2,ceph,nfsd,ubifs,nilfs2} \
  /lib/modules/*/kernel/arch/x86/kvm || true

echo " * remove unused firmware (sound, wifi)"
rm -rf /usr/lib/firmware/*wifi* \
  /usr/lib/firmware/v4l* \
  /usr/lib/firmware/dvb* \
  /usr/lib/firmware/{yamaha,korg,liquidio,emu,dsp56k,emi26} \
  /usr/lib/firmware/{ath9k,ath10k} || true

echo " * dropping big and compressing small cracklib dict"
mv -f /usr/share/cracklib/cracklib_small.hwm /usr/share/cracklib/pw_dict.hwm || true
mv -f /usr/share/cracklib/cracklib_small.pwd /usr/share/cracklib/pw_dict.pwd || true
mv -f /usr/share/cracklib/cracklib_small.pwi /usr/share/cracklib/pw_dict.pwi || true
gzip -9 /usr/share/cracklib/pw_dict.pwd || true

# 100MB of locale archive is kind unnecessary; we only do en_US.utf8
# this will clear out everything we don't need; 100MB => 2.1MB.
echo " * minimizing locale-archive binary / memory size"
localedef --list-archive | grep -Eiv '(en_US|fdi)' | xargs localedef -v --delete-from-archive || true
mv /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl || true
/usr/sbin/build-locale-archive || true

echo " * purging all other locale data"
ls -d /usr/share/locale/* | grep -v fdi | xargs rm -rf || true

echo " * purging images"
rm -rf /usr/share/backgrounds/* /usr/share/kde4/* /usr/share/anaconda/pixmaps/rnotes/* || true

echo " * purging rubygems cache"
rm -rf /usr/share/gems/cache/* || true

echo " * truncating various logfiles"
for log in yum.log dracut.log lastlog yum.log; do
    truncate -c -s 0 /var/log/${log} || true
done

echo " * removing trusted CA certificates"
truncate -s0 /usr/share/pki/ca-trust-source/ca-bundle.trust.crt || true
update-ca-trust

echo " * cleaning up yum cache and removing rpm database"
dnf clean all
rm -rf /var/lib/{yum,rpm}/* || true

# no more python loading after this step
echo " * removing python precompiled *.pyc files"
find /usr/lib64/python*/ /usr/lib/python*/ -name *py[co] -print0 | xargs -0 rm -f || true

%end

# NOTE Do NOT add any other sections after %packages
%packages --excludedocs --instLangs=en --excludeWeakdeps
# Packages requires to support this output format go here
@core
kernel
isomd5sum
dracut-config-generic
dracut-live
system-logos
selinux-policy-targeted
bash
sudo
dosfstools
fuse-libs
-gnupg2-smime
libss
-pinentry
-qemu-guest-agent
-shared-mime-info
-trousers
-xfsprogs
-xkeyboard-config
-chrony
-dracut-config-rescue
-prelink
-setserial
-ed
authconfig
-wireless-tools
-alsa-sof-firmware
-atmel-firmware
-ipw2100-firwmare
-ipw2200-firmware
-iwl7260-firmware
-iwl3160-firmware
-iwl6000g2b-firmware
-iwl6000g2a-firmware
-iwl5000-firmware
-iwl6050-firmware
-iwl2030-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl105-firmware
-iwl1000-firmware
-iwl6000-firmware
-iwl100-firmware
-iwl5150-firmware
-iwl4965-firmware
-iwl3945-firmware
-liquidio-firmware
-netronome-firmware
-libertas-usb8388-firmware
-linux-firmware-whence
-zd1211-firmware
# Remove the kbd bits
-kbd
-usermode
-subscription-manager
-rhn-setup

# file system stuff
-dmraid
-lvm2

# sound and video
-alsa-lib
-alsa-firmware
-alsa-tools-firmware
-ivtv-firmware

# logos and graphics
-plymouth
-centos-logos
-fedora-logos
-fedora-release-notes

# other packages
-postfix
-audit
-rsyslog
-authconfig
-tuned
-sg3_utils
-rhnsd
-firewalld

-@base

# NOTE lorax-composer will add the blueprint packages below here, including the final %end%packages
