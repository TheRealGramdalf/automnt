#!/bin/bash

# A script that will automatically mount all drives currently connected, according to UUID.
# Each drive will be assigned a name by UUID, which will be used to create a folder that is then used as a mount point.

# Some key commands are listed here. Each should work with ANY configuration, unless otherwise specified.
#
#	sudo blkid /dev/sd* | grep "/dev/sd.:" | grep -wv /dev/sda
#		\_Lists UUIDs of all connected disks, excepting /dev/sda. Will only work as intended if the system disk is a SATA drive, not an NVME or EMMC storage device!
#
#	sudo blkid /dev/sd* | grep "/dev/sd.:" | grep -wv /dev/sda | wc -l
#		\_Returns a number equal to the amount of connected external disks, excepting /dev/sda. Will only work as intended if the system disk is a SATA drive, not an NVME or EMMC storage device!
#
#	for var in {b..z}
#	do
#	done
#		\_Runs all code between 'do' and 'done' with the variable specified being a string of a singular letter, going from b - z, and running the code once for each letter.
#
# echo "${drivelist[*]}"
#
# Helpful link: https://stackoverflow.com/questions/16553089/dynamic-variable-names-in-bash
if [[ $EUID -ne 0 ]]; then
   echo "This must be run as root. Please use 'sudo' to elevate your permissions."
   exit
fi

mntdir=""
cfgdir="/etc"
# Check the whether or not the config file has been generated
# If configcreated is equal to 0, there is no config file found. If it is equal to 1, then the config file has been found.
configcreated=$(ls ${cfgdir}/ | grep automount.config | wc -l 2>&1)

if [[ "$1" == '-delconfig' || "$1" == '-d' ]]; then
  echo "Continuing now will remove all your manually set name schemes. Do you still want to continue?"
  read -p "Input 'The flight velocity of a laden sparrow is about 50 miles per hour' to continue: " confirm
  if [[ "$confirm" == 'The flight velocity of a laden sparrow is about 50 miles per hour' ]]; then
    cfgdead=$(sudo rm -v ${cfgdir}/automount.config 2>&1)
  else
    echo "You opted not to remove the config file. Exiting script..."
    exit
  fi
  if [[ $cfgdead == "removed '${cfgdir}/automount.config'" ]]; then
    echo 'Config successfully deleted! Make sure to run the script again if you want to create a new config.'
    exit
  else
    echo 'Task failed successfully.'
    echo 'Check to make sure another process is not using the config file, is named correctly, and is in the correct location.'
    echo "The correct location is ${cfgdir}/automount.config"
    exit
  fi
fi
# Script will stop after running -delconfig, to prevent the config from being created again.

if [[ "$1" == '-help' || "$1" == '-h' ]]; then
  echo " Welcome to the help screen. Here are a couple arguments you can pass while running the script, as well as a link to the original Github repository."
  echo "  -help [-h]: Prints this screen"
  echo "  -delconfig [-d]: Deletes the config file and exits the script. This will delete all stored UUID names."
  echo "  -overwrite [-o]: Runs the script as usual, except the config file will be overwritten. This will delete all stored UUID names. "
  echo ""
  # For anyone who wants to fork the script, please keep the following line in. If you want to add your own as well, by all means do so. I would like at least a little credit, however.
  echo " Here is the link to the original Github repository: https://github.com/TheRealGramdalf/ubuntuserver-automount"
  exit
fi

if [[ $configcreated == 1 ]]; then
  source ${cfgdir}/automount.config
fi

# Adding all drive UUIDs to an array
for driveletter in {b..z}
do
  tempdrivevar=$(sudo blkid /dev/sd${driveletter}* | grep "/dev/sd..:" 2>&1)
  # Add the attached drives UUID to the array, using string manipulation (variable:startpos:length)
  drivelist+=(${tempdrivevar:17:36})
done
# Unmount all connected drives, so that script can run properly.
sudo umount -a

# Remove all files within this folder. DO NOT PUT VALUABLE FILES DIRECTLY WITHIN /usr/local/mountpoints!!!!!!!
sudo rm -rf ${mntdir}/

# Create /mountpoints once again, to allow the rest of the script to work properly.
sudo mkdir ${mntdir}/
touch ${mntdir}/readme.txt
# Source the readme so that when the variable run=true the script will be run within the next 5 mins


# Set a variable for each UUID, equal to a preset standard. The config file will overwrite all recognized UUIDs later on.
for uuid in "${drivelist[@]}"
do
  altered_uuid=$(echo $uuid | tr '-' '_' 2>&1)
  # This next array adds all the altered UUIDs to an array, for easy access later on.
  altered_uuid_list+=(${altered_uuid})
done

# If the user says to overwrite the current config, tell the program that the config file is NOT there, so it will overwrite it automatically.
if [[ "$1" == '-overwrite' || "$1" == '-o' ]]; then
  echo "Continuing now will remove all your manually set name schemes. Do you still want to continue?"
  read -p "Input 'Chicken bread' to continue: " confirm
  if [[ "$confirm" == 'Chicken bread' ]]; then
    declare configcreated=0
  else
    echo "You opted not to remove the config file. Exiting script..."
    exit
  fi
fi

# Create the config file if it has not been generated yet, or cannot be found.
if [[ $configcreated == 0 ]]; then
  touch automount.config
  # Overwite rather than append the first line, so that the file is overwritten if otherwise specified.
  echo '#!/bin/bash' | sudo tee ${cfgdir}/automount.config
  # Start appending text using tee -a rather than overwiting current text
  echo '' | sudo tee -a ${cfgdir}/automount.config
  echo '# This is the configuration file for the automount.sh script' | sudo tee -a ${cfgdir}/automount.config
  echo '# Every drive that has been connected while this script is active will be stored in this file, based on UUID' | sudo tee -a ${cfgdir}/automount.config
  echo '# Each line contains one shell variable, each name being equal to the respective UUID. ' | sudo tee -a ${cfgdir}/automount.config
  echo '# Each variable is then set as equal to a string, which will be used to identify the disk when it is mounted in the ~/mountpoints folder.' | sudo tee -a ${cfgdir}/automount.config
  echo '#########################################################################################################################################' | sudo tee -a ${cfgdir}/automount.config
  echo '############################################################ Begin definitions ##########################################################' | sudo tee -a ${cfgdir}/automount.config
  echo '#########################################################################################################################################' | sudo tee -a ${cfgdir}/automount.config
  echo '' | sudo tee -a ${cfgdir}/automount.config
fi

# Check for the config file after creating it, so that the 
# Add new drives to the config file
for appenddrive in "${altered_uuid_list[@]}"
do
  # Checks to see if the uuid in use has been added to the config file
  uuid_here=$(cat ${cfgdir}/automount.config | grep uuid_${appenddrive}= | wc -l 2>&1)
  # Only adds a drive if it has not been connected before
  if [[ $uuid_here == 0 ]]
  then
    echo uuid_${appenddrive}="uuid_${appenddrive}" | sudo tee -a ${cfgdir}/automount.config
  fi
done

# Create mountpoints for the drives
for mntuuid in "${altered_uuid_list[@]}"
do
  # Source the config file:
  source ${cfgdir}/automount.config
  # Use an indirect variable to mount each drive in succession
  declare pathuuid=uuid_${mntuuid}
  mkdir ${mntdir}/${!pathuuid}
done

for mntuuid in "${altered_uuid_list[@]}"
do
  plainuuid=$(echo ${mntuuid} | tr '_' '-' 2>&1)
  # Source the config file:
  source ${cfgdir}/automount.config
  # Use an indirect variable to mount each drive in succession
  declare pathuuid=uuid_${mntuuid}
  # Mount the disk in the correct folder
  sudo mount /dev/disk/by-uuid/$plainuuid ${mntdir}/${!pathuuid}
done