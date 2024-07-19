# win-recovery-crowdstrike-19-07-24

udpate : The image is not bootable at the moment, fork if you know how to fix or wait for an update

This can only help if your windows partition is *unencrypted*

burn the ISO in the [releases](https://github.com/Brunwo/win-recovery-crowdstrike-19-07-24/releases/) tab to a bootable device (USB stick)


##  or manually run from sources :  

download a base ISO linux distro like: 

http://www.tinycorelinux.net/downloads.html

or 

    wget http://www.tinycorelinux.net/15.x/x86/release/Core-current.iso

clone this repo, then run the script with the base ISO of your choice :

    chmod +x create_custom_iso.sh

    ./create_custom_iso.sh Core-current.iso


When the computer boots from the USB stick, the script will automatically delete the faulty crowdstrike .sys file in windows drivers folder After the script completes, you can reboot the computer without the USB device and check if the BSOD issue is resolved.

I would need feedback, as I'm not affected
