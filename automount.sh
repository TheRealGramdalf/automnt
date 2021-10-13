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
   echo "If you have already entered youre password in this session, you will not be prompted fo your password."
   sleep 3
   sudo echo ''
fi

# These variables determine the path in which the config and mount directories are. Please make sure the path ends WITHOUT a '/', or the file paths will be messed up.
mntdir="/home/ncadmin/Automount"
cfgdir="/etc"

if [[ "$1" == "-cronread" ]]
then
  source ${mntdir}/readme.md
  if [[ "$refresh" != "true" ]]
  then
    exit
    echo "refresh=${refresh}. Not calling script."
  else
    echo "refresh=true. Continuing script."
  fi
fi

# Before checking the config file, set $configcreated to 0, so that the script can detect if the config file should be generated.
configcreated=0
# Check the whether or not the config file has been generated
# If configcreated is NULL, there is no config file found. If it is equal to 1, then the config file has been found.
[ -f "${cfgdir}/automount.config" ] && configcreated=1

if [[ "$1" == '-delconfig' || "$1" == '-d' ]]; then
  echo "Continuing now will remove all your manually set name schemes. Do you still want to continue?"
  read -p "Do you want to continue? (y/n)" confirm
  if [[ "$confirm" == 'y' ]]
  then
    cfgdead=$(sudo rm -v ${cfgdir}/automount.config 2>&1)
  else
    echo "You opted not to remove the config file. Exiting script..."
    exit
  fi
  if [[ $cfgdead == "removed '${cfgdir}/automount.config'" ]]
  then
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
  echo " Here is the link to the original Github repository: https://github.com/TheRealGramdalf/automount"
  exit
fi

if [[ $configcreated == 1 ]]; then
  source ${cfgdir}/automount.config
fi

# Adding all drive UUIDs to an array
for driveletter in {b..z}
do
  tempdrivevar=$(sudo blkid /dev/sd${driveletter}* | grep -o ' UUID="[^"\r\n]*"' | tr -d '"' )
  # Add the attached drives UUID to the array, using string manipulation (variable:startpos:length)
  drivelist+=(${tempdrivevar:6})
done

# Unmount all connected drives, so that script can run properly.
null=$(sudo umount -a 2>&1)

# Remove all files within this folder. DO NOT PUT VALUABLE FILES DIRECTLY WITHIN THE MOUNT FOLDER!!!!!
null=$(sudo rm -r ${mntdir}/* 2>&1)

# Create a readme file for the automation side of things. Look inside the file to find out what this does.
touch ${mntdir}/readme.md
echo "#!/bin/bash" | sudo tee ${mntdir}/readme.md
echo "" | sudo tee -a ${mntdir}/readme.md
echo "# This is the readme file for the automount script, which has been implemented by a system admin." | sudo tee -a ${mntdir}/readme.md
echo "# Because of how the program works, files placed directly within ${mntdir} will be deleted every time the system is run." | sudo tee -a ${mntdir}/readme.md
echo "# Since that is the case, treat this as you would a trash can. Once emptied, it is nigh impossible to recover them!" | sudo tee -a ${mntdir}/readme.md
echo "" | sudo tee -a ${mntdir}/readme.md
echo "# This file also serves another purpose. Below you will find a line that says 'refresh=false'." | sudo tee -a ${mntdir}/readme.md
echo "# If you change this value to 'true', and save the file, then the drives contained within this folder will be unmounted and remounted." | sudo tee -a ${mntdir}/readme.md
echo "# Please make sure that no file transfers are in progress before doing this!" | sudo tee -a ${mntdir}/readme.md
echo "" | sudo tee -a ${mntdir}/readme.md
echo "refresh=false" | sudo tee -a ${mntdir}/readme.md 

# Set a variable for each UUID, equal to a preset standard. The config file will overwrite all recognized UUIDs later on.
for uuid in "${drivelist[@]}"
do
  altered_uuid=$(echo "$uuid" | tr '-' '_')
  # This next array adds all the altered UUIDs to an array, for easy access later on.
  altered_uuid_list+=("${altered_uuid}")
done

# If the user says to overwrite the current config, tell the program that the config file is NOT there, so it will overwrite it automatically.
if [[ "$1" == '-overwrite' || "$1" == '-o' ]]
then
  echo "Continuing now will remove all your manually set name schemes. Do you still want to continue?"
  read -p "Do you want to continue? (y/n): " confirm
  if [[ "$confirm" == 'y' ]]
  then
    declare configcreated=0
  else
    echo "You opted not to remove the config file. Exiting script..."
    exit
  fi
fi

# Create the config file if it has not been generated yet, or cannot be found.
if [[ $configcreated == 0 ]]; then
  touch ${cfgdir}automount.config
  # Overwite rather than append the first line, so that the file is overwritten if otherwise specified.
  echo '#!/bin/bash' | sudo tee ${cfgdir}/automount.config 
  # Start appending text using tee -a rather than overwiting current text
  echo '' | sudo tee -a ${cfgdir}/automount.config
  echo '# This is the configuration file for the automount.sh script' | sudo tee -a ${cfgdir}/automount.config 
  echo '# Every drive that has been connected while this script is active will be stored in this file, based on UUID' | sudo tee -a ${cfgdir}/automount.config 
  echo '# Each line contains one shell variable, each name being equal to the respective UUID.' | sudo tee -a ${cfgdir}/automount.config 
  echo '# Each variable is then set as equal to a string, which will be used to identify the disk when it is mounted in the ~/mountpoints folder.' | sudo tee -a ${cfgdir}/automount.config
  echo '#########################################################################################################################################' | sudo tee -a ${cfgdir}/automount.config 
  echo '############################################################ Begin definitions ##########################################################' | sudo tee -a ${cfgdir}/automount.config 
  echo '#########################################################################################################################################' | sudo tee -a ${cfgdir}/automount.config 
  echo '' | sudo tee -a ${cfgdir}/automount.config
  clear
fi

# Check for the config file after creating it, so that the
# Add new drives to the config file
for appenddrive in "${altered_uuid_list[@]}"
do
  # Checks to see if the uuid in use has been added to the config file
  uuid_here=$(cat "${cfgdir}"/automount.config | grep uuid_"${appenddrive}"= | wc -l 2>&1)
  # Only adds a drive if it has not been connected before
  if [[ $uuid_here == 0 ]]
  then
    echo "uuid_${appenddrive}=uuid_${appenddrive}" | sudo tee -a ${cfgdir}/automount.config
  fi
done

# Create mountpoints for the drives
for mntuuid in "${altered_uuid_list[@]}"
do
  # Source the config file:
  source ${cfgdir}/automount.config
  # Use an indirect variable to mount each drive in succession
  declare pathuuid=uuid_${mntuuid}
  mkdir ${mntdir}/"${!pathuuid}"
done

for mntuuid in "${altered_uuid_list[@]}"
do
  plainuuid=$(echo "${mntuuid}" | tr '_' '-' 2>&1)
  # Source the config file:
  source ${cfgdir}/automount.config
  # Use an indirect variable to mount each drive in succession
  declare pathuuid=uuid_${mntuuid}
  # Mount the disk in the correct folder
  sudo mount /dev/disk/by-uuid/"$plainuuid" ${mntdir}/"${!pathuuid}"
done
# sudo find ${mntdir} -type f -exec chmod 666 {} \;
# sudo find ${mntdir} -type d -exec chmod 777 {} \;
# sudo chown -R --preserve-root www-data:www-data ${mntdir}
