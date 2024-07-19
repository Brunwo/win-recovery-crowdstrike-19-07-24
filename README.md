# win-recovery-crowdstrike-19-07-24
win-recovery-crowdstrike-19-07-24


download base ISO linux distro : 

http://www.tinycorelinux.net/downloads.html

or 

    wget http://www.tinycorelinux.net/15.x/x86/release/Core-current.iso

clone this repo, then run the script :

    chmod +x create_custom_iso.sh

    ./create_custom_iso.sh Core-current.iso


When the computer boots from the USB stick, the script will automatically run, delete any files matching the wildcard pattern, and unmount the Windows partition. After the script completes, you can reboot the computer and check if the BSOD issue is resolved.
