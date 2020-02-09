#!/bin/bash
# Version 1.0
# Omar Omar - 2017

# If valid, on-board speaker beep ONCE
# Get Device Info from devData.dat file outputed by addDevRules.sh
# Double checks device
# Mounts dev
# Grabs all jpg, png, mov, mp4, etc...
# Moves data into specific dir
# Unmount dev
# Once all data successfully transfered, beep twice
# Service that runs this script: img-transfer-script.service


# Functions Start

function boardBeep() # Speaker Beep (On-Board)
{
	sleep `echo $1`
	sh -c "echo -e '\a' > /dev/console"
}

function devMount() # Mounts device | depending on argument
{
	if [ "$1" == 3 ]; then
		jmtpfs $MountLoc	# Mount MTP device to location
		
	else
		Model=`cat $LOC/devData.dat | awk '/Model/{getline; print}'`	# Retrieves Device's Model
		Serial=`cat $LOC/devData.dat | awk '/Serial/{getline; print}'`	# Retrieves Device's Serial
		
		DevBlock=`lsblk -S | grep $Model | cut -d " " -f1` # Gets block's disk
		part='1'	# Get's block's part number
		partition=$DevBlock$part	# Gets the partition block of device
		
		if [ "$1" == 1 ]; then # Mount
			mount /dev/$partition $MountLoc	# Mount device into usb1 location
			
		elif [ "$1" == 2 ]; then #UnMount
			umount /dev/$partition
			
		fi
	fi
}

function transfer() # Transfers specific data {one each line in order to bypass spaces in files}
{
	if [ -d "$MountLoc" ]; then	# Checks if directory exists | Checks if input ouput error
		DIRstatus='Exists'	# Set status of DIR | No error
		
		sleep 1s # Wait a sec to catch up
		
		#find $MountLoc/ \( -name '*.jpeg'  -o -name '*.jpg' -o -name '*.png' -o -name '*.mp4'   \) -exec cp -p "{}" $DataOutput/Temp \;	# Finds and COPIES all intances specified data into a Temp directory
		
		find $MountLoc/ \( -name '*.jpeg'  -o -name '*.jpg' -o -name '*.png' -o -name '*.mp4'   \) -exec mv "{}" $DataOutput/Temp \;	# Finds and MOVES all intances specified data into a directory
		
	else
		DIRstatus='NOPE'	# Set status of DIR | Error Found
	fi
}

function organizeFiles() # Loop through file names and stat them to organize neatly
{
	sleep 1s # Wait a sec to catch up
	cd $DataOutput/Temp	# Go to that location
	
	for file in $PWD/*
	do
		fileName=`echo $file | rev | cut -d "/"  -f1 | rev`	# Get the name of the file
		
		modDate=`find -name "$fileName" -type f -exec stat "{}" \; | grep -i Modify | cut -d " " -f2` # Get full modified date | type -f so that only file are read and not directories
		yearDate=`echo $modDate | cut -d "-" -f1`	# Cut out year
		monthDate=`echo $modDate | cut -d "-" -f2` # Cut out month
		
		mkdir -p $DataOutput/Pictures/$yearDate/$monthDate	# Make directory of date for file in Pictures DIR
		
		#find -name "$fileName" -type f -exec cp -p "{}" $DataOutput/$yearDate/$monthDate \;	# Copies file to destination while preserving
		
		
		find -name "$fileName" -type f -exec mv "{}" $DataOutput/Pictures/$yearDate/$monthDate \;	# Moves file to destination (preserves anyway) [Pictures DIR]
		
	done
}

function iInterfaceCheck()
{
	iInterface=`cat $LOC/devData.dat | awk '/iInterface/{getline; print}'`	# Retrieves Device's Model
	
	if [ -z $iInterface ]; then	# Mount device
		devStatus='Non-MTP'	# Set global variable in order to unmount
		devMount 1
	
	else
		if [ $iInterface == "MTP" ]; then	# Mount MTP
			devStatus='MTP'
			devMount 3 
		fi
	fi
}


# Useful Variables
LOC="/share/PublicDocuments/Projects/AutomatedImgGrabber/" # Project's location
MountLoc="/media/usb1"	# Mounted Device Location
DataOutput="/share/Family-HDD/"	#	Location of data being outputed to 
																			# [Temp | Pictures]


# On-Board Seaker Beep (x1) - Indicates it's running this script
boardBeep 2


# Checks if device is MTP | Determine mounting
iInterfaceCheck


# Begin Transfer
transfer


# Organize Files (Year|Month)
if [ $DIRstatus == 'Exists' ]; then
    organizeFiles
fi


# Unmount Device
if [ $devStatus == 'Non-MTP' ]; then
	devMount 2
	
else
	fusermount -u $MountLoc	# UnMounts MTP Device
fi


# On-Board Seaker Beep (x2) - Indicates script has finished
boardBeep 0.1
boardBeep 0.1
