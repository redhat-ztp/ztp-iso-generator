How to use this repo
====================

The purpose of this set of scripts is to create a minimal ISO suitable for booting a minimal
RHCOS, and then download the rootfs and ignition from remote endpoints.

To achieve that, please execute the following steps:

1. Execute generate_rhcos_iso.sh - This will create an small ISO, based on syslinux, with
the contents from https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.6/latest/ 
(live-initramfs and live-kernel). It will place the final iso on /tmp/coreos.iso path

2. In order to customize the image, please execute inject_config_files.sh . It takes the following
parameters:

- original ISO to configure
- final ISO path
- ignition_path
- rootfs path
- kernel arguments

This script will take the original ISO and will inject the needed parameters in the kernel arguments,
in order to configure the network with the given settings, and then downloading rootfs and ignition
from remote urls.
After rootfs has been mounted, the specified ignition will run, allowing to customize the image in
the usual way.

Sample:

./rhcos-iso/inject_config_files.sh /tmp/coreos.iso /tmp/final_coreos.iso http://192.168.111.1:8080/ignition_url http://192.168.111.1:8080/rootfs.img "ip=192.168.111.20::192.168.111.200:255.255.255.0:cluster.local:eno2:on:8.8.8.8"
