# Version 1.0
# Omar Omar - 2017

# Adds a device to /etc/udev/rules.d/
# Rules authorizes autorun to a script


# Functions
function listUSBDev()   # List all connected USB Devices
{
    echo -e "\n${bold}Device List:${normal}\n"
    lsusb       # Show current USB connections
    echo        # Leave space
}


function addDev()       # Add Device into rules directory
{
    echo -e "\nSelect which device you'd like to add: \c"
    read devNum extra       # Get device line

    if [ $devNum -gt 0 ] && [ $devNum -lt $((deviceCount + 1)) ]; then	# Display which line has been added
    	echo -e "\n${bold}`lsusb | sed ''$devNum'!d'`${normal} || \c"
    	
    	DevInfo=`lsusb -v | grep -i iSerial | sed -n ''$devNum',1p'`	# Obtain Info of selected device from devNum and returns 1 paragraph
    	echo -e "${bold}ADDED SUCCESSFULLY!${normal}\n"
		
		serial=`echo $DevInfo | awk '{print $3}'` # Obtains the device's serial number
		Model=`lsusb | sed -n ''$devNum',1p' | awk '{print $NF}'` # Obtains the Model of device, awks the last field
		iInterface=`lsusb -v | grep -i iInterface | sed -n ''$devNum',1p' | awk '{print $3}'` # Obtains interface {if it's MTP or not}
		
		
		echo -e "[Serial] \n $serial \n\n[Model] \n $Model \n\n[iInterface] \n $iInterface" # Display info
		echo -e "[Serial] \n $serial \n\n[Model] \n $Model \n\n[iInterface] \n $iInterface" > $dataDump # Save to data file
		
    	echo "ACTION==\"add\", ENV{DEVTYPE}==\"usb_device\", ATTRS{serial}==\""$serial"\", RUN+=\""$script""\" > $rulesLoc # Output into rules

    else
    	echo -e "\n${bold}Device Out of Range!${normal}"
    fi

    echo 				# Add space
}


function remDevAll()	# Removes device rule file from rulesLoc
{
	echo -e "\n${bold}All Devices Have Been Removed From Rules Dir${normal}\n"
	rm $rulesLoc
}


function restartUdev()	# Restarts Udev and Udev Rules to refresh change
{
	udevadm control --reload
	udevadm control --reload-rules
}

# Define Variables
script="/bin/systemctl --no-block start img-transfer-script.service" # Service that runs the script | In order for the script not to be killed
dataDump="/share/PublicDocuments/Projects/AutomatedImgGrabber/devData.dat"
rulesLoc="/etc/udev/rules.d/99-custom.rules"

selection=1
deviceCount="`lsusb | wc -l`"       # Number of devices
re='^[0-9]+$'                       # All numbers Variable

bold=$(tput bold)                   # Bold  Format
normal=$(tput sgr0)                 # Normal Format


## Loop Menu ##
while [ "$selection" -ne 0 ]; do
    echo -e "1)Show Devices \t2)Add Device \t3)Remove All Devices \t0)Exit\n"
    echo -e "Enter Selection: \c"
    read selection extra

# Check if input is valid
    if ! [[ $selection =~ $re ]]; then
        echo -e "\nInvalid input\n"
        selection=999
    fi


# Run Functions based on selection
    if [ $selection = 1 ]; then
        listUSBDev

    elif [ $selection = 2 ]; then
       addDev

    elif [ $selection = 3 ]; then
    	remDevAll

    elif [ $selection = 0 ]; then
    	echo -e "\n${bold}GOOD BYE${normal}\n"
    	exit 0

    else
    	echo -e "\n${bold}Invalid Selection!${normal}\n"
    fi
done

# Reset UDEV
restartUdev