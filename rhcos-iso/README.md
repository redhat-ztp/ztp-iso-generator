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
- extra config folder

Kernel arguments and config folder are optional, you can skip just by passing a blank value ""
into the position of these parameters.

This script will take the original ISO and will inject the needed parameters in the kernel arguments,
in order to configure the network with the given settings, and then downloading rootfs and ignition
from remote urls.
It will also take the extra config folder that you specify, and inject it into the ramdisk, allowing
to configure network, run additional services, etc...

After rootfs has been mounted, the specified ignition will run, allowing to customize the image in
the usual way.

Sample:

For kernel arguments:

./rhcos-iso/inject_config_files.sh /tmp/coreos.iso /tmp/final_coreos.iso http://192.168.111.1:8080/ignition_url http://192.168.111.1:8080/rootfs.img "ip=192.168.111.20::192.168.111.200:255.255.255.0:cluster.local:eno2:on:8.8.8.8"

For extra ramdisk:


./rhcos-iso/inject_config_files.sh /tmp/coreos.iso /tmp/final_coreos.iso http://192.168.111.1:8080/ignition_url http://192.168.111.1:8080/rootfs.img "" /path/to/config_folder

In the config folder, you need to create a filesystem that will replicate the folder structure that you want to see on the ramdisk. For example:

/tmp/network_config/
└── etc
    └── NetworkManager
        └── system-connections
            └── eno1.nmconnection

Will copy the file to /etc/NetworkManager/system-connections/eno1.nmconnection, if you specify /tmp/network_config as the config folder

The files placed on this config folder will change their ownership to root. But it's still important that you give the right permissions to all the
folders and files inside this structure.
