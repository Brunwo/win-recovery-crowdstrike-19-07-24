#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Check if Tiny Core Linux ISO is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-tinycore.iso>"
    exit 1
fi

TINYCORE_ISO="$1"

# Create directories for mounting ISO and working directory
sudo mkdir -p ./mnt/iso ./tmp/tinycore-custom

# Mount the Tiny Core Linux ISO
sudo mount -o loop "$TINYCORE_ISO" ./mnt/iso

# Copy contents to a temporary directory
sudo cp -r ./mnt/iso/* ./tmp/tinycore-custom

# Unmount the ISO
sudo umount ./mnt/iso

# Create the opt directory if it doesn't exist
sudo mkdir -p ./tmp/tinycore-custom/opt

# Create a custom script to delete the problematic driver
cat <<'EOF' | sudo tee ./tmp/tinycore-custom/opt/delete_driver.sh > /dev/null
#!/bin/sh
# Function to check if a partition contains a Windows installation
is_windows_partition() {
    local partition=$1
    mkdir -p /mnt/temp
    if mount /dev/$partition /mnt/temp 2>/dev/null; then
        if [ -d "/mnt/temp/Windows/System32" ]; then
            umount /mnt/temp
            return 0
        fi
        umount /mnt/temp
    fi
    return 1
}

# Find Windows partition
WINDOWS_PART=""
for partition in $(fdisk -l | grep '^/dev' | awk '{print $1}'); do
    if is_windows_partition $partition; then
        WINDOWS_PART=$partition
        break
    fi
done

if [ -z "$WINDOWS_PART" ]; then
    echo "No Windows partition found."
    exit 1
fi

echo "Windows partition found: $WINDOWS_PART"

# Mount the Windows partition
mkdir -p /mnt/windows
if ! mount $WINDOWS_PART /mnt/windows; then
    echo "Failed to mount the Windows partition."
    exit 1
fi


# Delete the problematic driver(s)
DRIVER_PATH="/mnt/windows/Windows/System32/drivers/CrowdStrike/C-00000291*.sys"
DELETED_FILES=0
for FILE in $DRIVER_PATH; do
    if [ -f "$FILE" ]; then
        if rm "$FILE"; then
            echo "Deleted: $FILE"
            DELETED_FILES=$((DELETED_FILES + 1))
        else
            echo "Failed to delete: $FILE"
        fi
    else
        echo "File not found: $FILE"
    fi
done

if [ $DELETED_FILES -eq 0 ]; then
    echo "No matching files were found or deleted."
else
    echo "Operation completed. $DELETED_FILES file(s) deleted."
fi

# Unmount the partition
umount /mnt/windows

echo "Script execution completed."
EOF

# Make the script executable
sudo chmod +x ./tmp/tinycore-custom/opt/delete_driver.sh

# Modify isolinux.cfg to add our custom script
sudo sed -i '/^append/ s/$/ tce=sda1 opt=sda1/' ./tmp/tinycore-custom/boot/isolinux/isolinux.cfg

# Create a new initrd.gz with our custom script
sudo mkdir -p ./tmp/initrd
cd ./tmp/initrd
sudo gzip -dc ../tinycore-custom/boot/core.gz | sudo cpio -i -d -H newc

# Copy our custom script to the initrd
sudo cp ../tinycore-custom/opt/delete_driver.sh ./opt/


# Update existing bootlocal.sh in the initrd to run our script
if [ -f ./opt/bootlocal.sh ]; then
    echo "/opt/delete_driver.sh" | sudo tee -a ./opt/bootlocal.sh > /dev/null
else
    echo "#!/bin/sh" | sudo tee ./opt/bootlocal.sh > /dev/null
    echo "/opt/delete_driver.sh" | sudo tee -a ./opt/bootlocal.sh > /dev/null
    sudo chmod +x ./opt/bootlocal.sh
fi

# Repack the initrd
sudo find . | sudo cpio -o -H newc | sudo gzip -9 > ../new_core.gz
sudo mv ../new_core.gz ../tinycore-custom/boot/core.gz
cd ../..

# Create a new ISO image
cd ./tmp/tinycore-custom
sudo mkisofs -l -J -R -V "TinyCore Custom" -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -o ../../tinycore-custom.iso .

# Clean up
cd ../..
sudo rm -rf ./tmp ./mnt

echo "Custom ISO created at $(pwd)/tinycore-custom.iso"