#!/bin/bash

# wget http://www.tinycorelinux.net/15.x/x86/release/Core-current.iso 

# Check if Tiny Core Linux ISO is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-tinycore.iso>"
    exit 1
fi

TINYCORE_ISO="$1"

# Create directories for mounting ISO and working directory
mkdir -p ./mnt/iso ./mnt/usb ./tmp/tinycore-custom

# Mount the Tiny Core Linux ISO
sudo mount -o loop "$TINYCORE_ISO" ./mnt/iso

# Copy contents to a temporary directory with proper permissions
sudo cp -r ./mnt/iso/* ./tmp/tinycore-custom

# Unmount the ISO
sudo umount ./mnt/iso

# Create the opt directory if it doesn't exist
sudo mkdir -p ./tmp/tinycore-custom/opt

# Create the bootlocal.sh file if it doesn't exist
if [ ! -f ./tmp/tinycore-custom/opt/bootlocal.sh ]; then
    sudo touch ./tmp/tinycore-custom/opt/bootlocal.sh
fi

# Create a custom script to delete the problematic driver
cat <<EOF | sudo tee ./tmp/tinycore-custom/delete_driver.sh > /dev/null
#!/bin/sh

# Identify the Windows partition
WINDOWS_PART=\$(lsblk -o NAME,LABEL | grep -i 'OS\|Windows' | awk '{print \$1}')
if [ -z "\$WINDOWS_PART" ]; then
    echo "Windows partition not found!"
    exit 1
fi

# Mount the Windows partition
mkdir -p /mnt/windows
sudo mount /dev/\$WINDOWS_PART /mnt/windows

# Delete the problematic driver(s)
DRIVER_PATH="/mnt/windows/Windows/System32/drivers/CrowdStrike/C-00000291*.sys"
for FILE in \$DRIVER_PATH; do
    if [ -f "\$FILE" ]; then
        sudo rm "\$FILE"
        echo "Deleted: \$FILE"
    else
        echo "File not found: \$FILE"
    fi
done

# Unmount the partition
sudo umount /mnt/windows
EOF

# Make the script executable
sudo chmod +x ./tmp/tinycore-custom/delete_driver.sh

# Add the custom script to Tiny Core Linux's startup sequence
echo "/delete_driver.sh" | sudo tee -a ./tmp/tinycore-custom/opt/bootlocal.sh > /dev/null

# Create a new ISO image
cd ./tmp/tinycore-custom
sudo mkisofs -l -J -R -V "TinyCore Custom" -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -o ../tinycore-custom.iso .

# Clean up
cd ..
sudo rm -rf ./tmp/tinycore-custom

echo "Custom ISO created at $(pwd)/tinycore-custom.iso"

