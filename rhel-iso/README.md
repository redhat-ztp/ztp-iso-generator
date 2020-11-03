# ztp-iso-generator
Tooling to generate the initial ISO to start ZTP project

# How to build a minimal ISO

Follow instructions on [https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/composing_a_customized_rhel_system_image/index]

This process will be relying on composer-cli in order to build smallest possible RHEL live iso.

To achieve that, we need 2 files: 

kickstart
blueprint

Lorax comes with a pre-created kickstart file, used to produce the Live ISO, but it’s adding extra content not needed. So we need to modify the kickstart file at /usr/share/lorax/composer/live-iso.ks to
remove unneeded packages, and also to execute additional post-install scripts (note that podman pull still does not work). A sample kickstart looks like:

https://github.com/redhat-ztp/ztp-iso-generator/blob/main/build-iso/live-iso.ks

Second step is to create the blueprint. It allows to customize the image, adding users or extra services (this is wip, we need to add our call-home service):

https://github.com/redhat-ztp/ztp-iso-generator/blob/main/build-iso/ztp-blueprint.toml


We push the blueprint to composer:

composer-cli blueprints push small-livecd-iso.toml

And we generate the image, based on the liveiso type:

 composer-cli compose start small-livecd-iso live-iso

We can check status with:

composer-cli compose list
f32b0ed4-cdf6-4ea0-b6da-26fdd246da64 RUNNING small-livecd-iso 0.0.3 live-iso

And when it finishes we can download the image with:
 composer-cli compose image <compose_id>

It will download an ISO that we can use to mount in virtualmedia.

# How to configure the ISO

Once the boot ISO has been generated, it is possible to inject some extra configuration files that can be used by other processes.
In order to do that, you can use the https://github.com/redhat-ztp/ztp-iso-generator/blob/main/customize-iso/inject_config_files.sh script,
with the following usage:

./customize-iso/inject_config_files.sh <original_iso> <path_to_config_folder> <final_iso>

This script will simply take the content of the config folder specified, and will copy it inside the Live CD. Once the image is booted,
all this content can simply be accessed from /run/initramfs/live/config path.

A sample config folder can look like:

```bash
/tmp/config/
├── network
│   └── ifcfg-eno2
└── settings
```
