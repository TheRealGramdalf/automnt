#!/bin/bash

# This script will add a folder at the root directory called /startupscripts, and add the script to /usr/bin. 
# It will also update the script if it has already been installed.
# After installation, call automount from a terminal to run the script. You may optionally add a crontab entry,it should look something like.
# '@reboot sudo automount' 
# This will automatically call the script at boot. In order to add it, you should log in as root, so that the script can run with the correct permissions. 
# Type 'sudo -i' to log in as root (you may need to enter your password, and your user needs to have sudo priviledges)
# Enter 'crontab -e' to edit the crontab file
# Enter the crontab entry at the bottom of the file. (crontab entry should look like this: '@reboot sudo automount')
# Save and exit, and you are done! Every time you reboot, the script will be run and all drives will be mounted.

# Check to see if the script is being run with root priviledges
if [[ $EUID -ne 0 ]]; then
   echo "This must be run as root. Please use 'sudo' to elevate your permissions."
   exit
fi

echo "Are you sure you want to install? This will overwrite any modifications you might have made to the older version of the script."
read -p "Your config file, however, will NOT be overwritten. Type 'Yes' to continue: " confirm
if [[ "$confirm" == "Yes" ]]
then
    echo "You chose to install! If you did this by mistake, hit ctrl + c in..."
    sleep 1
    echo "5.."
    sleep 1
    echo "4.."
    sleep 1
    echo "3.."
    sleep 1
    echo "2.."
    sleep 1
    echo "1.."
    echo "Commence install!"
    lastdel=`sudo rm -v /usr/bin/automount`
    if [[ "$lastdel" == "removed '/usr/bin/automount'" ]]
    then
        echo "Removed old version from /usr/bin/"
    else
        echo "Either an older version has not been installed, or the file could not be found. Commencing with script anyways."
    fi
    sudo cp automount.sh /usr/bin/automount
    sudo chmod +x /usr/bin/automount
    sscreated=$(sudo mkdir /startupscripts 2>&1)
    if [[ "$sscreated" == "mkdir: cannot create directory ‘/startupscripts’: File exists" ]]
    then
        echo "Did not create the /startupscripts/ directory. Either the file is already there, or something went wrong."
    else
        echo "Created the /startupscripts/ directory"
    fi
    installdone=$(ls /usr/bin/ | grep "automount" | wc -l 2>&1)
    if [[ "$installdone" == 1 ]]
    then
        echo "Success! The script has been successfully installed."
    else
        echo " Uh oh. Something went wrong with installing the script. Try checking the file paths to make sure everything works."
        echo "Exiting script"
        exit
    fi
else
    echo "You opted not to install. Exiting script."
    exit
fi