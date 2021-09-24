# Automount.sh Script || By TheRealGramdalf

BASH script designed for Ubuntu server 20.04 LTS which will automatically mount all connected USB drives, complete with a UUID-based naming config file. Feel free to ask questions about anything in this script. At the moment, the script has only been tested on Ubuntu Server 20.04 LTS, but I may test it on other distros in the future.

After running the script at least once, the config file will be generated. Inside you have your [namescheme =unclear]. By default, if a drive has never been connected before using this script, the script will create a new entry (such as `drive-by-uuid-some-random-uuid-goes-here`. If it has been connected before, the script will read the name from the config file, and use that as the mountpoint instead.

# Command Options

When running the script, you have a couple arguments that you can set before running. As of this current version, only one is supported at a time.
[add args here]

# Installation
In order to install the script, run install.sh using the following command: "chmod +x install.sh && sudo bash install.sh"
For more information, check the top of install.sh
